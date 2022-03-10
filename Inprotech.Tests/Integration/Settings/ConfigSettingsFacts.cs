using System;
using System.Linq;
using Inprotech.Integration.Settings;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.Integration.Settings
{
    public class ConfigSettingsReadingFacts : FactBase
    {
        [Fact]
        public void ShouldReturnNullIfSettingNotPresent()
        {
            Assert.Null(new ConfigSettings(Db)["doesntexist"]);
        }

        [Fact]
        public void ShouldReturnValueIfPresentWithKeyCaseMismatch()
        {
            new ConfigSetting("thekey") {Value = "thevalue"}.In(Db);
            Assert.Equal("thevalue", new ConfigSettings(Db)["ThEkEy"]);
        }

        [Fact]
        public void ShouldReturnValueIfSettingPresent()
        {
            new ConfigSetting("thekey") {Value = "thevalue"}.In(Db);
            Assert.Equal("thevalue", new ConfigSettings(Db)["thekey"]);
        }

        [Fact]
        public void ShouldThrowIfKeyIsEmpty()
        {
            Assert.Throws<IndexOutOfRangeException>(() => new ConfigSettings(Db)[string.Empty]);
        }

        [Fact]
        public void ShouldThrowIfKeyIsNull()
        {
            Assert.Throws<IndexOutOfRangeException>(() => new ConfigSettings(Db)[null]);
        }
    }

    public class ConfigSettingsGetValueOrDefaultFacts : FactBase
    {
        [Fact]
        public void ShouldReturnDefaultIfConversionFails()
        {
            new ConfigSetting("thekey") {Value = "thevalue"}.In(Db);
            Assert.True(new ConfigSettings(Db).GetValueOrDefault("thekey", true));
        }

        [Fact]
        public void ShouldReturnSpecifiedDefaultIfSettingDoesNotExist()
        {
            Assert.True(new ConfigSettings(Db).GetValueOrDefault("thekey", true));
        }

        [Fact]
        public void ShouldReturnTypeDefaultIfConversionFails()
        {
            new ConfigSetting("thekey") {Value = "thevalue"}.In(Db);
            Assert.False(new ConfigSettings(Db).GetValueOrDefault<bool>("thekey"));
        }

        [Fact]
        public void ShouldReturnTypeDefaultIfSettingDoesNotExist()
        {
            Assert.Equal(string.Empty, new ConfigSettings(Db).GetValueOrDefault<string>("thekey"));
        }

        [Fact]
        public void ShouldReturnValueIfSettingDoesExist()
        {
            new ConfigSetting("thekey") {Value = "thevalue"}.In(Db);
            Assert.Equal("thevalue", new ConfigSettings(Db).GetValueOrDefault("thekey", "thedefaultvalue"));
        }
    }

    public class ConfigSettingsWritingFacts : FactBase
    {
        [Fact]
        public void ShouldAllowEmptyValueToBeSet()
        {
            new ConfigSettings(Db)["thekey"] = string.Empty;
            Assert.Equal(string.Empty, Db.Set<ConfigSetting>().Single(s => s.Key == "thekey").Value);
        }

        [Fact]
        public void ShouldSetValueIfSettingIsAlreadyPresent()
        {
            new ConfigSetting("thekey") {Value = "existingvalue"}.In(Db);
            new ConfigSettings(Db)["thekey"] = "thevalue";
            Assert.Equal("thevalue", Db.Set<ConfigSetting>().Single(s => s.Key == "thekey").Value);
        }

        [Fact]
        public void ShouldSetValueIfSettingNotPresent()
        {
            new ConfigSettings(Db)["thekey"] = "thevalue";
            Assert.Equal("thevalue", Db.Set<ConfigSetting>().Single(s => s.Key == "thekey").Value);
        }

        [Fact]
        public void ShouldThrowIfKeyIsEmpty()
        {
            Assert.Throws<IndexOutOfRangeException>(() => new ConfigSettings(Db)[string.Empty] = "thevalue");
        }

        [Fact]
        public void ShouldThrowIfKeyIsNull()
        {
            Assert.Throws<IndexOutOfRangeException>(() => new ConfigSettings(Db)[null] = "thevalue");
        }

        [Fact]
        public void ShouldThrowIfValueIsNull()
        {
            Assert.Throws<ArgumentNullException>(() => new ConfigSettings(Db)["thekey"] = null);
        }

        [Fact]
        public void ShouldUpdateExistingValueWithCaseMismatchedKey()
        {
            new ConfigSetting("thekey") {Value = "existingvalue"}.In(Db);
            new ConfigSettings(Db)["tHeKeY"] = "thevalue";
            Assert.Equal("thevalue", Db.Set<ConfigSetting>().Single(s => s.Key == "thekey").Value);
            Assert.False(Db.Set<ConfigSetting>().Any(s => s.Key == "tHeKeY"));
        }
    }

    public class ConfigSettingsSetValueFacts : FactBase
    {
        class TestClass
        {
            public string Value { get; set; }

            public override string ToString()
            {
                return $"TestClass-Value:{Value}";
            }
        }

        [Fact]
        public void ShouldSetComplexTypeAsAString()
        {
            var testClass = new TestClass {Value = "testvalue"};

            new ConfigSettings(Db).SetValue("thekey", testClass);
            Assert.Equal(testClass.ToString(), Db.Set<ConfigSetting>().Single(s => s.Key == "thekey").Value);
        }

        [Fact]
        public void ShouldSetValueTypeAsAString()
        {
            new ConfigSettings(Db).SetValue("thekey", true);
            Assert.Equal(true.ToString(), Db.Set<ConfigSetting>().Single(s => s.Key == "thekey").Value);
        }
    }

    public class ConfigSettingsDeleteFacts : FactBase
    {
        [Fact]
        public void ShouldDeleteExistingSettingWithMatchingKey()
        {
            new ConfigSetting("thekey") {Value = "existingvalue"}.In(Db);
            new ConfigSettings(Db).Delete("thekey");
            Assert.False(Db.Set<ConfigSetting>().Any(s => s.Key == "thekey"));
        }

        [Fact]
        public void ShouldDeleteExistingSettingWithMatchingKeyWithMismatchedCase()
        {
            new ConfigSetting("thekey") {Value = "existingvalue"}.In(Db);
            new ConfigSettings(Db).Delete("tHeKeY");
            Assert.False(Db.Set<ConfigSetting>().Any(s => s.Key == "thekey"));
        }

        [Fact]
        public void ShouldNotThrowWhenSettingDoesNotExist()
        {
            new ConfigSettings(Db).Delete("thekey");
        }

        [Fact]
        public void ShouldThrowWhenKeyIsEmpty()
        {
            Assert.Throws<ArgumentNullException>(() => new ConfigSettings(Db).Delete(string.Empty));
        }

        [Fact]
        public void ShouldThrowWhenKeyIsNull()
        {
            Assert.Throws<ArgumentNullException>(() => new ConfigSettings(Db).Delete(null));
        }
    }
}