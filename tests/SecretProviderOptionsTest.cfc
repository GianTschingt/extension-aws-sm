component extends="org.lucee.cfml.test.LuceeTestCase" labels="aws-sm" {

	// "smRaw" is a Secrets Manager provider with "jsonTraversal": false,
	// "psPrefix" is a Parameter Store provider with "pathPrefix": "/lucee-test/app" (no trailing slash)

	function run(testResults, testBox) {

		describe("JSON traversal with AWS Secrets Manager Provider", function() {

			it("can read a value from a nested JSON structure", function() {
				expect(SecretProviderGet("test-nested.db.user", "sm", true)).toBe("nested-user");
				expect(SecretProviderGet("test-nested.db.port", "sm", true)).toBe("5432");
			});

			it("returns a nested structure as JSON", function() {
				var result = SecretProviderGet("test-nested.db", "sm", true);
				expect(isJSON(result)).toBeTrue();
				var parsed = deserializeJSON(result);
				expect(parsed.user).toBe("nested-user");
				expect(parsed.port).toBe(5432);
			});

			it("throws for a key that does not exist in the JSON structure", function() {
				expect(function() {
					SecretProviderGet("test-nested.db.missing", "sm", true);
				}).toThrow();
			});

			it("throws when traversing a secret that is not JSON", function() {
				expect(function() {
					SecretProviderGet("test-secret.anything", "sm", true);
				}).toThrow();
			});

		});

		describe("AWS Secrets Manager Provider with jsonTraversal false", function() {

			it("returns the raw JSON of a secret", function() {
				var result = SecretProviderGet("mysecret", "smRaw", true);
				expect(isJSON(result)).toBeTrue();
				expect(deserializeJSON(result).password).toBe("sm-secret");
			});

			it("does not split the key at dots", function() {
				// looks for a secret named [mysecret.password], which does not exist
				expect(function() {
					SecretProviderGet("mysecret.password", "smRaw", true);
				}).toThrow();
			});

		});

		describe("Binary secrets with AWS Secrets Manager Provider", function() {

			it("returns a binary secret as Base64", function() {
				var result = SecretProviderGet("binary-secret", "sm", true);
				expect(result).toBe(toBase64("binary-value"));
				expect(toString(toBinary(result))).toBe("binary-value");
			});

		});

		describe("SecureString with AWS Parameter Store Provider", function() {

			it("returns a SecureString parameter decrypted", function() {
				expect(SecretProviderGet("secure-parameter", "ps", true)).toBe("secure-value");
			});

			it("stores a value as SecureString and reads it back", function() {
				var key = "test-secure-#createUUID()#";
				SecretProviderSet(key, "secure-roundtrip", "ps");
				try {
					expect(SecretProviderGet(key, "ps", true)).toBe("secure-roundtrip");
				}
				finally {
					SecretProviderRemove(key, "ps");
				}
			});

		});

		describe("AWS Parameter Store Provider with pathPrefix", function() {

			it("prepends the path to the key", function() {
				expect(SecretProviderGet("db-password", "psPrefix", true)).toBe("prefixed-value");
				expect(SecretProviderGet("/lucee-test/app/db-password", "ps", true)).toBe("prefixed-value");
			});

			it("only lists the parameters below the path, without the path", function() {
				var names = SecretProviderListNames("psPrefix");
				expect(arrayFind(names, "db-password")).toBeGT(0);
				expect(arrayFind(names, "/lucee-test/app/db-password")).toBe(0);
				expect(arrayFind(names, "test-parameter")).toBe(0);
			});

			it("does not find parameters outside the path", function() {
				expect(function() {
					SecretProviderGet("test-parameter", "psPrefix", true);
				}).toThrow();
			});

			it("sets and removes parameters below the path", function() {
				var key = "test-prefix-#createUUID()#";
				SecretProviderSet(key, "prefixed-set", "psPrefix");
				expect(SecretProviderGet("/lucee-test/app/" & key, "ps", true)).toBe("prefixed-set");
				expect(arrayFind(SecretProviderListNames("psPrefix"), key)).toBeGT(0);

				SecretProviderRemove(key, "psPrefix");
				expect(arrayFind(SecretProviderListNames("ps"), "/lucee-test/app/" & key)).toBe(0);
			});

		});

		describe("SecretProviderGet without a provider name", function() {

			it("finds a key that only one provider has", function() {
				// the Secrets Manager providers have no secret [myparameter], so this comes from Parameter Store
				expect(SecretProviderGet("myparameter.password") & "").toBe("ps-secret");
			});

			it("throws when no provider has the key", function() {
				expect(function() {
					SecretProviderGet("non-existent-key-#createUUID()#");
				}).toThrow();
			});

		});
	}

}
