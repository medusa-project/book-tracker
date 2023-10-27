The private keys for the `sp-cert` files are stored in the encrypted application
configuration at `saml.sp_private_key`.

Use `rails credentials:edit -e <environment>` to edit.

`itrust.pem` is from the
[iTrust metadata](https://md.itrust.illinois.edu/itrust-metadata/itrust-metadata.xml)
at `//EntityDescriptor[@entityID=urn:mace:incommon:uiuc:edu]/IDPSSODescriptor/KeyDescriptor[@use=signing]/ds:KeyInfo/ds:X509Data/ds:X509Certificate`.

See [Shibboleth, Establishing Your Service in the I-Trust Federation](https://answers.uillinois.edu/illinois/page.php?id=48457)
