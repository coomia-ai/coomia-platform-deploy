"""The browser and Next server must use distinct backend addressing."""

from pathlib import Path
from string import Template
import unittest

import yaml


class EnterpriseUiRuntimeContract(unittest.TestCase):
    def test_server_rendering_uses_the_dedicated_api_service(self):
        path = Path(__file__).resolve().parents[1] / "22-classic-enterprise-ui.yaml"
        rendered = Template(path.read_text(encoding="utf-8")).safe_substitute(
            CLASSIC_ENTERPRISE_UI_IMAGE_PULL_SECRETS_BLOCK="",
            CLASSIC_ENTERPRISE_UI_INGRESS_POLICY_BLOCK="",
        )
        deployment = next(
            document
            for document in yaml.safe_load_all(rendered)
            if document["kind"] == "Deployment"
        )
        ui = next(
            container
            for container in deployment["spec"]["template"]["spec"]["containers"]
            if container["name"] == "ui"
        )
        values = {item["name"]: item.get("value") for item in ui["env"]}
        self.assertEqual(
            values.get("INTERNAL_API_URL"), "http://classic-enterprise-api:8050"
        )
        self.assertNotIn("NEXT_PUBLIC_API_URL", values)


if __name__ == "__main__":
    unittest.main()
