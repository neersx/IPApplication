using System;
using System.Linq;
using Inprotech.Integration.Settings;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.Model.Components.System.Settings
{
    public class ConfigSettingsFacts : FactBase
    {
        ConfigSettings CreateSubject()
        {
            return new ConfigSettings(Db);
        }

        [Fact]
        public void ShouldReturnNullIfSettingNotPresent()
        {
            var subject = CreateSubject();

            Assert.Null(subject["doesntexist"]);
        }

        [Fact]
        public void ShouldReturnValueIfPresentWithKeyCaseMismatch()
        {
            new ConfigSetting("thekey") {Value = "thevalue"}.In(Db);

            var subject = CreateSubject();
            
            Assert.Equal("thevalue", subject["ThEkEy"]);
        }

        [Fact]
        public void ShouldReturnValueIfSettingPresent()
        {
            new ConfigSetting("thekey") {Value = "thevalue"}.In(Db);

            var subject = CreateSubject();

            Assert.Equal("thevalue", subject["thekey"]);
        }

        [Fact]
        public void ShouldThrowIfKeyIsEmpty()
        {
            var subject = CreateSubject();

            Assert.Throws<IndexOutOfRangeException>(() => subject[string.Empty]);
        }

        [Fact]
        public void ShouldThrowIfKeyIsNull()
        {
            var subject = CreateSubject();

            Assert.Throws<IndexOutOfRangeException>(() => subject[null]);
        }
    }

    public class ConfigSettingsGetValueOrDefaultFacts : FactBase
    {
        ConfigSettings CreateSubject()
        {
            return new ConfigSettings(Db);
        }

        [Fact]
        public void ShouldReturnDefaultIfConversionFails()
        {
            new ConfigSetting("thekey") {Value = "thevalue"}.In(Db);
            
            var subject = CreateSubject();

            Assert.True(subject.GetValueOrDefault("thekey", true));
        }

        [Fact]
        public void ShouldReturnSpecifiedDefaultIfSettingDoesNotExist()
        {
            var subject = CreateSubject();

            Assert.True(subject.GetValueOrDefault("thekey", true));
        }

        [Fact]
        public void ShouldReturnTypeDefaultIfConversionFails()
        {
            new ConfigSetting("thekey") {Value = "thevalue"}.In(Db);
            
            var subject = CreateSubject();

            Assert.False(subject.GetValueOrDefault<bool>("thekey"));
        }

        [Fact]
        public void ShouldReturnTypeDefaultIfSettingDoesNotExist()
        {
            var subject = CreateSubject();

            Assert.Equal(string.Empty, subject.GetValueOrDefault<string>("thekey"));
        }

        [Fact]
        public void ShouldReturnValueIfSettingDoesExist()
        {
            new ConfigSetting("thekey") {Value = "thevalue"}.In(Db);
            
            var subject = CreateSubject();

            Assert.Equal("thevalue", subject.GetValueOrDefault("thekey", "thedefaultvalue"));
        }
    }

    public class ConfigSettingsWritingFacts : FactBase
    {
        ConfigSettings CreateSubject()
        {
            return new ConfigSettings(Db);
        }

        [Fact]
        public void ShouldAllowEmptyValueToBeSet()
        {
            var subject = CreateSubject();

            subject["thekey"] = string.Empty;
            
            Assert.Equal(string.Empty, Db.Set<ConfigSetting>().Single(s => s.Key == "thekey").Value);
        }

        [Fact]
        public void ShouldSetValueIfSettingIsAlreadyPresent()
        {
            new ConfigSetting("thekey") {Value = "existingvalue"}.In(Db);
            
            var subject = CreateSubject();
            
            subject["thekey"] = "thevalue";

            Assert.Equal("thevalue", Db.Set<ConfigSetting>().Single(s => s.Key == "thekey").Value);
        }

        [Fact]
        public void ShouldSetValueIfSettingNotPresent()
        {
            var subject = CreateSubject();

            subject["thekey"] = "thevalue";

            Assert.Equal("thevalue", Db.Set<ConfigSetting>().Single(s => s.Key == "thekey").Value);
        }

        [Fact]
        public void ShouldThrowIfKeyIsEmpty()
        {
            var subject = CreateSubject();
            
            Assert.Throws<IndexOutOfRangeException>(() => subject[string.Empty] = "thevalue");
        }

        [Fact]
        public void ShouldThrowIfKeyIsNull()
        {
            var subject = CreateSubject();

            Assert.Throws<IndexOutOfRangeException>(() => subject[null] = "thevalue");
        }

        [Fact]
        public void ShouldThrowIfValueIsNull()
        {
            var subject = CreateSubject();

            Assert.Throws<ArgumentNullException>(() => subject["thekey"] = null);
        }

        [Fact]
        public void ShouldUpdateExistingValueWithCaseMismatchedKey()
        {
            new ConfigSetting("thekey") {Value = "existingvalue"}.In(Db);
            
            var subject = CreateSubject();
            
            subject["tHeKeY"] = "thevalue";

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
        ConfigSettings CreateSubject()
        {
            return new ConfigSettings(Db);
        }
        
        [Fact]
        public void ShouldSetComplexTypeAsAString()
        {
            var testClass = new TestClass {Value = "testvalue"};
            
            var subject = CreateSubject();
            
            subject.SetValue("thekey", testClass);
            
            Assert.Equal(testClass.ToString(), Db.Set<ConfigSetting>().Single(s => s.Key == "thekey").Value);
        }

        [Fact]
        public void ShouldSetValueTypeAsAString()
        {
            var subject = CreateSubject();
            
            subject.SetValue("thekey", true);
            
            Assert.Equal(true.ToString(), Db.Set<ConfigSetting>().Single(s => s.Key == "thekey").Value);
        }
    }

    public class ConfigSettingsDeleteFacts : FactBase
    {
        ConfigSettings CreateSubject()
        {
            return new ConfigSettings(Db);
        }

        [Fact]
        public void ShouldDeleteExistingSettingWithMatchingKey()
        {
            new ConfigSetting("thekey") {Value = "existingvalue"}.In(Db);
            
            var subject = CreateSubject();
            
            subject.Delete("thekey");
            
            Assert.False(Db.Set<ConfigSetting>().Any(s => s.Key == "thekey"));
        }

        [Fact]
        public void ShouldDeleteExistingSettingWithMatchingKeyWithMismatchedCase()
        {
            new ConfigSetting("thekey") {Value = "existingvalue"}.In(Db);
            
            var subject = CreateSubject();
            subject.Delete("tHeKeY");

            Assert.False(Db.Set<ConfigSetting>().Any(s => s.Key == "thekey"));
        }

        [Fact]
        public void ShouldNotThrowWhenSettingDoesNotExist()
        {
            var subject = CreateSubject();
         
            subject.Delete("thekey");
        }

        [Fact]
        public void ShouldThrowWhenKeyIsEmpty()
        {
            var subject = CreateSubject();

            Assert.Throws<ArgumentNullException>(() => subject.Delete(string.Empty));
        }

        [Fact]
        public void ShouldThrowWhenKeyIsNull()
        {
            var subject = CreateSubject();

            Assert.Throws<ArgumentNullException>(() => subject.Delete(null));
        }
    }
}