using System.Linq;
using Inprotech.Setup.Actions;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class ImportExistingAttachmentSettingsFacts
    {
        public class ParseIManageSettings
        {
            public class ParseAttachmentSettingMethod
            {
                [Fact]
                public void ShouldParseCorrectly()
                {
                    var xml = "<attachment max-received-directories-count=\"100\" is-restricted=\"true\"" +
                              " allowed-file-extensions=\"doc,docx,pdf,csv,xml,ppt,pptx,odt,ods,xls,xlsx\">" +
                              "<storage-locations>" +
                              "<clear />" +
                              "<add name=\"test4\" path=\"C:\\Assets\" />" +
                              "<add name=\"adfv\" path=\"C:\\inetpub\" />" +
                              "</storage-locations>" +
                              "<network-drives>" +
                              "<clear />" +
                              "<add drive-letter=\"C\" unc-path=\"C:\\Intel\" />" +
                              "<add drive-letter=\"U\" unc-path=\"C:\\git\" />" +
                              "</network-drives>" +
                              "</attachment>";

                    var result = ImportExistingAttachmentSettings.IwsSettingParser.ParseAttachmentSetting(xml);

                    Assert.NotNull(result);
                    Assert.True(result.IsRestricted);
                    Assert.Equal(2, result.NetworkDrives.Length);
                    Assert.Equal(2, result.StorageLocations.Length);
                    Assert.Equal("doc,docx,pdf,csv,xml,ppt,pptx,odt,ods,xls,xlsx", result.StorageLocations.First().AllowedFileExtensions);
                    Assert.Equal("doc,docx,pdf,csv,xml,ppt,pptx,odt,ods,xls,xlsx", result.StorageLocations.Last().AllowedFileExtensions);
                }

                [Fact]
                public void ShouldParseCorrectlyForEmptyData()
                {
                    var xml = "<attachment />";

                    var result = ImportExistingAttachmentSettings.IwsSettingParser.ParseAttachmentSetting(xml);

                    Assert.NotNull(result);
                    Assert.Empty(result.NetworkDrives);
                    Assert.Empty(result.StorageLocations);
                }
            }
            public class IsAttachmentSettingValidMethod
            {
                [Fact]
                public void ShouldFailIfEmpty()
                {
                    var xml = string.Empty;

                    var result = ImportExistingAttachmentSettings.IwsSettingParser.IsAttachmentSettingValid(xml);

                    Assert.False(result);
                }
                
                [Fact]
                public void ShouldFailIfDriveLetterMissing()
                {
                    var xml = "<attachment max-received-directories-count=\"100\" is-restricted=\"true\"" +
                              " allowed-file-extensions=\"doc,docx,pdf,csv,xml,ppt,pptx,odt,ods,xls,xlsx\">" +
                              "<storage-locations>" +
                              "<clear />" +
                              "<add name=\"test4\" path=\"C:\\Assets\" />" +
                              "<add name=\"adfv\" path=\"C:\\inetpub\" />" +
                              "</storage-locations>" +
                              "<network-drives>" +
                              "<clear />" +
                              "<add drive-letter=\"\" unc-path=\"C:\\Intel\" />" +
                              "<add drive-letter=\"U\" unc-path=\"C:\\git\" />" +
                              "</network-drives>" +
                              "</attachment>";

                    var result = ImportExistingAttachmentSettings.IwsSettingParser.IsAttachmentSettingValid(xml);

                    Assert.False(result);
                }
                
                [Fact]
                public void ShouldFailIUncPathMissing()
                {
                    var xml = "<attachment max-received-directories-count=\"100\" is-restricted=\"true\"" +
                              " allowed-file-extensions=\"doc,docx,pdf,csv,xml,ppt,pptx,odt,ods,xls,xlsx\">" +
                              "<storage-locations>" +
                              "<clear />" +
                              "<add name=\"test4\" path=\"C:\\Assets\" />" +
                              "<add name=\"adfv\" path=\"C:\\inetpub\" />" +
                              "</storage-locations>" +
                              "<network-drives>" +
                              "<clear />" +
                              "<add drive-letter=\"U\" unc-path=\"\" />" +
                              "<add drive-letter=\"U\" unc-path=\"C:\\git\" />" +
                              "</network-drives>" +
                              "</attachment>";

                    var result = ImportExistingAttachmentSettings.IwsSettingParser.IsAttachmentSettingValid(xml);

                    Assert.False(result);
                }
                
                [Fact]
                public void ShouldFailIfStorageLocationNameMissing()
                {
                    var xml = "<attachment max-received-directories-count=\"100\" is-restricted=\"true\"" +
                              " allowed-file-extensions=\"doc,docx,pdf,csv,xml,ppt,pptx,odt,ods,xls,xlsx\">" +
                              "<storage-locations>" +
                              "<clear />" +
                              "<add name=\"\" path=\"C:\\Assets\" />" +
                              "<add name=\"adfv\" path=\"C:\\inetpub\" />" +
                              "</storage-locations>" +
                              "<network-drives>" +
                              "<clear />" +
                              "<add drive-letter=\"\" unc-path=\"\" />" +
                              "<add drive-letter=\"U\" unc-path=\"C:\\git\" />" +
                              "</network-drives>" +
                              "</attachment>";

                    var result = ImportExistingAttachmentSettings.IwsSettingParser.IsAttachmentSettingValid(xml);

                    Assert.False(result);
                }
                
                [Fact]
                public void ShouldFailIfStorageLocationPathMissing()
                {
                    var xml = "<attachment max-received-directories-count=\"100\" is-restricted=\"true\"" +
                              " allowed-file-extensions=\"doc,docx,pdf,csv,xml,ppt,pptx,odt,ods,xls,xlsx\">" +
                              "<storage-locations>" +
                              "<clear />" +
                              "<add name=\"test4\" path=\"\" />" +
                              "<add name=\"adfv\" path=\"C:\\inetpub\" />" +
                              "</storage-locations>" +
                              "<network-drives>" +
                              "<clear />" +
                              "<add drive-letter=\"\" unc-path=\"\" />" +
                              "<add drive-letter=\"U\" unc-path=\"C:\\git\" />" +
                              "</network-drives>" +
                              "</attachment>";

                    var result = ImportExistingAttachmentSettings.IwsSettingParser.IsAttachmentSettingValid(xml);

                    Assert.False(result);
                }

                [Fact]
                public void ShouldSucceedIfValid()
                {
                    var xml = "<attachment max-received-directories-count=\"100\" is-restricted=\"true\"" +
                              " allowed-file-extensions=\"doc,docx,pdf,csv,xml,ppt,pptx,odt,ods,xls,xlsx\">" +
                              "<storage-locations>" +
                              "<clear />" +
                              "<add name=\"test4\" path=\"C:\\Assets\" />" +
                              "<add name=\"adfv\" path=\"C:\\inetpub\" />" +
                              "</storage-locations>" +
                              "<network-drives>" +
                              "<clear />" +
                              "<add drive-letter=\"C\" unc-path=\"C:\\Intel\" />" +
                              "<add drive-letter=\"U\" unc-path=\"C:\\git\" />" +
                              "</network-drives>" +
                              "</attachment>";

                    var result = ImportExistingAttachmentSettings.IwsSettingParser.IsAttachmentSettingValid(xml);

                    Assert.True(result);
                }

                [Fact]
                public void ShouldSucceedIfEmptyData()
                {
                    var xml = "<attachment />";

                    var result = ImportExistingAttachmentSettings.IwsSettingParser.IsAttachmentSettingValid(xml);

                    Assert.True(result);
                }
            }
        }
    }
}