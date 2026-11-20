"""Dedicated Enterprise project credentials must not need cluster-wide RBAC."""

from pathlib import Path
from string import Template
import os
import subprocess
import tempfile
import unittest

import yaml


class EnterpriseProjectCredentialContract(unittest.TestCase):
    def test_role_and_binding_are_limited_to_the_owned_namespace(self):
        path = (
            Path(__file__).resolve().parents[1]
            / "21-classic-enterprise-flink-namespace.yaml"
        )
        rendered = Template(path.read_text(encoding="utf-8")).safe_substitute(
            CLASSIC_ENTERPRISE_NAMESPACE="classic-enterprise-getai",
            CLASSIC_ENTERPRISE_FLINK_NAMESPACE="classic-enterprise-getai-flink",
        )
        documents = list(yaml.safe_load_all(rendered))
        self.assertEqual(
            [item["kind"] for item in documents], ["Namespace", "Role", "RoleBinding"]
        )
        role, binding = documents[1:]
        self.assertEqual(
            role["metadata"]["namespace"], "classic-enterprise-getai-flink"
        )
        self.assertEqual(
            role["rules"],
            [
                {
                    "apiGroups": [""],
                    "resources": ["secrets"],
                    "verbs": ["get", "create", "update", "delete"],
                }
            ],
        )
        self.assertEqual(
            binding["metadata"]["namespace"], role["metadata"]["namespace"]
        )
        self.assertEqual(
            binding["subjects"],
            [
                {
                    "kind": "ServiceAccount",
                    "name": "classic-enterprise-api",
                    "namespace": "classic-enterprise-getai",
                }
            ],
        )
        self.assertEqual(
            binding["roleRef"],
            {
                "apiGroup": "rbac.authorization.k8s.io",
                "kind": "Role",
                "name": role["metadata"]["name"],
            },
        )

    def test_api_iam_provider_is_an_explicit_rendered_value(self):
        path = Path(__file__).resolve().parents[1] / "20-classic-enterprise-api.yaml"
        for provider in ("minio", "rustfs"):
            with self.subTest(provider=provider):
                rendered = Template(path.read_text(encoding="utf-8")).safe_substitute(
                    CLASSIC_ENTERPRISE_API_IMAGE_PULL_SECRETS_BLOCK="",
                    CLASSIC_ENTERPRISE_API_INGRESS_POLICY_BLOCK="",
                    CLASSIC_ENTERPRISE_INGRESS_BLOCK="",
                    CLASSIC_ENTERPRISE_OBJECT_STORAGE_IAM_PROVIDER=provider,
                )
                config = next(
                    item
                    for item in yaml.safe_load_all(rendered)
                    if item["kind"] == "ConfigMap"
                )
                self.assertEqual(
                    config["data"]["OBJECT_STORAGE_IAM_PROVIDER"], provider
                )
                self.assertEqual(config["data"]["LICENSE_ENFORCEMENT"], "true")

    def test_real_renderer_resolves_namespaces_and_validates_iam_provider(self):
        root = Path(__file__).resolve().parents[1]
        environment = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith("CLASSIC_ENTERPRISE_")
        }
        environment.update(
            CLASSIC_ENTERPRISE_API_IMAGE="registry.local/coomia/api@sha256:" + "1" * 64,
            CLASSIC_ENTERPRISE_NAMESPACE="classic-enterprise-getai",
            CLASSIC_ENTERPRISE_FLINK_NAMESPACE="classic-enterprise-getai-flink",
            CLASSIC_ENTERPRISE_CORE_REVISION="3b4458d",
            CLASSIC_ENTERPRISE_ENTERPRISE_REVISION="e48eba3",
            CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION="a6cec49",
            CLASSIC_ENTERPRISE_RELEASE_INPUTS="2" * 64,
            VALIDATE_KUBECTL="0",
        )
        with tempfile.TemporaryDirectory() as directory:
            for provider in (None, "minio", "invalid"):
                with self.subTest(provider=provider):
                    selected = dict(environment)
                    if provider is not None:
                        selected["CLASSIC_ENTERPRISE_OBJECT_STORAGE_IAM_PROVIDER"] = (
                            provider
                        )
                    output = Path(directory) / f"{provider}.yaml"
                    result = subprocess.run(
                        [
                            os.environ.get("COOMIA_BASH", "bash"),
                            (root / "render-enterprise.sh").as_posix(),
                            output.as_posix(),
                        ],
                        env=selected,
                        capture_output=True,
                        text=True,
                        encoding="utf-8",
                        timeout=30,
                    )
                    if provider == "invalid":
                        self.assertNotEqual(result.returncode, 0)
                        self.assertIn("must be minio or rustfs", result.stderr)
                        self.assertFalse(output.exists())
                        continue
                    self.assertEqual(result.returncode, 0, result.stderr)
                    rendered = output.read_text(encoding="utf-8")
                    self.assertNotIn("${", rendered)
                    documents = list(yaml.safe_load_all(rendered))
                    binding = next(
                        item for item in documents if item["kind"] == "RoleBinding"
                    )
                    self.assertEqual(
                        binding["subjects"][0]["namespace"], "classic-enterprise-getai"
                    )
                    self.assertEqual(
                        binding["metadata"]["namespace"],
                        "classic-enterprise-getai-flink",
                    )
                    config = next(
                        item for item in documents if item["kind"] == "ConfigMap"
                    )
                    self.assertEqual(
                        config["data"]["OBJECT_STORAGE_IAM_PROVIDER"],
                        provider or "rustfs",
                    )


if __name__ == "__main__":
    unittest.main()
