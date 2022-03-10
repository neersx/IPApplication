using System.Xml.Linq;
using Inprotech.Setup.Actions;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class ImportExistingDmsSettingsFacts
    {
        public class ParseIManageSettings
        {
            [Fact]
            public void ShouldNotReturnDemoConfigurations()
            {
                var xml = " <worksite serverName=\"testServerName\" loginType=\"InprotechUsernameWithImpersonation\" impersonationPassword=\"testPassword\" version=\"Demo\" customerId=\"1\">" +
                          "           <databases>" +
                          "               <clear />" +
                          "               <add name=\"testDatabase1\" />" +
                          "               <add name=\"testDatabase2\" />" +
                          "           </databases>" +
                          "           <workspace>" +
                          "               <case searchField=\"CustomField1And2\" subclass=\"case_subclass\" subtype=\"work\" />" +
                          "               <nametypes>" +
                          "                   <clear />" +
                          "                   <add nametype=\"123\" subclass=\"ABC\" />" +
                          "                   <add nametype=\"456\" subclass=\"DEF\" />" +
                          "               </nametypes>" +
                          "            </workspace>" +
                          "       </worksite>";
                var xElement = XElement.Parse(xml);
                var result = ImportExistingDmsSettings.IwsSettingParser.ParseIManageSettings(xElement);

                Assert.Equal(0, result.Databases.Length);
            }

            [Fact]
            public void ShouldReturnValuesInCorrectFieldsIfNotDemo()
            {
                var xml = " <worksite serverName=\"testServerName\" loginType=\"InprotechUsernameWithImpersonation\" impersonationPassword=\"testPassword\" version=\"iManageCom\" customerId=\"1\">" +
                          "           <databases>" +
                          "               <clear />" +
                          "               <add name=\"testDatabase1\" />" +
                          "               <add name=\"testDatabase2\" />" +
                          "           </databases>" +
                          "           <workspace>" +
                          "               <case searchField=\"CustomField1And2\" subclass=\"testSubclass\" subtype=\"testSubType\" />" +
                          "               <nametypes>" +
                          "                   <clear />" +
                          "                   <add nametype=\"123\" subclass=\"ABC\" />" +
                          "                   <add nametype=\"456\" subclass=\"DEF\" />" +
                          "               </nametypes>" +
                          "            </workspace>" +
                          "       </worksite>";
                var xElement = XElement.Parse(xml);
                var result = ImportExistingDmsSettings.IwsSettingParser.ParseIManageSettings(xElement);

                Assert.Equal(1, result.Databases.Length);
                Assert.Equal("testDatabase1,testDatabase2", result.Databases[0].Database);
                Assert.Equal("testPassword", result.Databases[0].Password);
                Assert.Equal(1, result.Databases[0].CustomerId);

                Assert.Equal("CustomField1And2", result.Case.SearchField);
                Assert.Equal("testSubclass", result.Case.SubClass);
                Assert.Equal("testSubType", result.Case.SubType);

                Assert.Equal(2, result.NameTypes.Length);
                Assert.Equal("123", result.NameTypes[0].NameType);
                Assert.Equal("ABC", result.NameTypes[0].SubClass);
                Assert.Equal("456", result.NameTypes[1].NameType);
                Assert.Equal("DEF", result.NameTypes[1].SubClass);
            }
        }
    }
}