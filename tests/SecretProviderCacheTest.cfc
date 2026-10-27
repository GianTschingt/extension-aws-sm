component extends="org.lucee.cfml.test.LuceeTestCase" labels="aws-sm" {

	// the providers "smNoCache" / "psNoCache" (timeout 0) and "smCacheForever" / "psCacheForever" (timeout -1)
	// point to the same LocalStack instance, so a value changed through the uncached provider shows
	// whether the other one returns its cached value

	function beforeAll() {
		variables.smName = "test-cache-sm";
		variables.psName = "test-cache-ps";
	}

	function afterAll() {
		if (arrayFind(SecretProviderListNames("smNoCache"), variables.smName)) {
			SecretProviderRemove(variables.smName, "smNoCache");
		}
		if (arrayFind(SecretProviderListNames("psNoCache"), variables.psName)) {
			SecretProviderRemove(variables.psName, "psNoCache");
		}
	}

	function run(testResults, testBox) {
		describe("AWS Secrets Manager Provider with a negative timeout (cache until refresh)", function() {

			it("can get a seeded secret", function() {
				expect(SecretProviderGet("test-secret", "smCacheForever", true)).toBe("test-value");
			});

			it("can traverse a seeded JSON secret", function() {
				expect(SecretProviderGet("mysecret.password", "smCacheForever", true)).toBe("sm-secret");
			});

			it("returns the cached value after the secret was changed elsewhere", function() {
				SecretProviderSet(variables.smName, "first", "smNoCache");
				expect(SecretProviderGet(variables.smName, "smCacheForever", true)).toBe("first");

				SecretProviderSet(variables.smName, "second", "smNoCache");
				expect(SecretProviderGet(variables.smName, "smNoCache", true)).toBe("second");
				expect(SecretProviderGet(variables.smName, "smCacheForever", true)).toBe("first");
			});

			it("updates the cache when the secret is set through the cached provider", function() {
				SecretProviderSet(variables.smName, "third", "smCacheForever");
				expect(SecretProviderGet(variables.smName, "smCacheForever", true)).toBe("third");
				expect(SecretProviderGet(variables.smName, "smNoCache", true)).toBe("third");
			});

			it("removes the value from the cache when the secret is removed through the cached provider", function() {
				SecretProviderRemove(variables.smName, "smCacheForever");
				sleep(500);
				expect(function() {
					SecretProviderGet(variables.smName, "smCacheForever", true);
				}).toThrow();
			});

		});

		describe("AWS Parameter Store Provider with a negative timeout (cache until refresh)", function() {

			it("can get a seeded parameter", function() {
				expect(SecretProviderGet("test-parameter", "psCacheForever", true)).toBe("test-value");
			});

			it("can traverse a seeded JSON parameter", function() {
				expect(SecretProviderGet("myparameter.password", "psCacheForever", true)).toBe("ps-secret");
			});

			it("returns the cached value after the parameter was changed elsewhere", function() {
				SecretProviderSet(variables.psName, "first", "psNoCache");
				expect(SecretProviderGet(variables.psName, "psCacheForever", true)).toBe("first");

				SecretProviderSet(variables.psName, "second", "psNoCache");
				expect(SecretProviderGet(variables.psName, "psNoCache", true)).toBe("second");
				expect(SecretProviderGet(variables.psName, "psCacheForever", true)).toBe("first");
			});

			it("updates the cache when the parameter is set through the cached provider", function() {
				SecretProviderSet(variables.psName, "third", "psCacheForever");
				expect(SecretProviderGet(variables.psName, "psCacheForever", true)).toBe("third");
				expect(SecretProviderGet(variables.psName, "psNoCache", true)).toBe("third");
			});

			it("removes the value from the cache when the parameter is removed through the cached provider", function() {
				SecretProviderRemove(variables.psName, "psCacheForever");
				sleep(500);
				expect(function() {
					SecretProviderGet(variables.psName, "psCacheForever", true);
				}).toThrow();
			});

		});

		describe("AWS providers with timeout 0 (no cache)", function() {

			it("Secrets Manager returns the current value on every call", function() {
				SecretProviderSet(variables.smName, "uncached-1", "smNoCache");
				expect(SecretProviderGet(variables.smName, "smNoCache", true)).toBe("uncached-1");
				SecretProviderSet(variables.smName, "uncached-2", "smCacheForever");
				expect(SecretProviderGet(variables.smName, "smNoCache", true)).toBe("uncached-2");
			});

			it("Parameter Store returns the current value on every call", function() {
				SecretProviderSet(variables.psName, "uncached-1", "psNoCache");
				expect(SecretProviderGet(variables.psName, "psNoCache", true)).toBe("uncached-1");
				SecretProviderSet(variables.psName, "uncached-2", "psCacheForever");
				expect(SecretProviderGet(variables.psName, "psNoCache", true)).toBe("uncached-2");
			});

		});
	}

}
