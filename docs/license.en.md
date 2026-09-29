# License Operations

English | [简体中文](license.md)

The platform validates entitlement when `LICENSE_ENFORCEMENT=true`. License files, online activation credentials, and License state are sensitive assets.

## Online mode

Set `LICENSE_MODE=online` and the publisher-provided `LICENSE_SERVER_URL`. The API container requires access to that service, working DNS, accurate system time, and a valid CA trust chain.

After activation, confirm the product, validity period, feature scope, and instance identity on the administration page. For any error, preserve the API logs and current time before contacting the publisher.

## Offline mode

1. Store the publisher's public key in a customer-controlled, read-only location.
2. Set `LICENSE_MODE=offline` and the absolute public-key path in `compose/.env`.
3. Start the platform and import the signed JWT License file from the administration page.

The public key verifies signatures and cannot issue Licenses. The License private key must never be present in the customer package, images, or runtime.

## Renewal and expiry

Obtain a replacement before expiry and import it through the administration page. Verify both the displayed state and licensed functions. Do not edit JWT content or License state files inside the container.

Post-expiry behavior depends on the release policy and may include warnings, restrictions on new jobs, or denial of licensed functions. Expiry must not delete data volumes.

## Backup and audit

License state is stored in the `license-state` volume. Back it up at the same recovery point as the platform database. Audit records should include version, instance identity, License fingerprint, activation time, expiry time, and operator, but not the complete License content.

## Common errors

- "Already used": the License is bound to another instance or does not allow repeated activation.
- "Invalid signature": the public key, file content, or issuing environment does not match.
- "Not effective": check container time, License mode, public-key mount, and API logs.
- "Service unavailable": verify API health first; HTTP 503 is generally not caused solely by License expiry.
