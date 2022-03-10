using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Names;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{ 
    [TestFixture]
    [Category(Categories.E2E)]
    public class ImportCases : IntegrationTest
    {
        readonly List<string> _filesAdded = new List<string>();

        [TearDown]
        public void CleanupFiles()
        {
            foreach (var file in _filesAdded)
                FileSetup.DeleteFile(file);
        }

        [TestFixture]
        [Category(Categories.E2E)]
        public class Journey : ImportCases
        {
            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            public void ImportCpaXmlJourney(BrowserType browserType)
            {
                var driver = BrowserProvider.Get(browserType);

                var invalidcpaxml = CreateFile("invalidcpaxml.xml");

                var validcpaxml = CreateFile("validcpaxml.xml");

                var user = new Users().WithPermission(ApplicationTask.BulkCaseImport).Create();

                SignIn(driver, "/#/bulkcaseimport/import", user.Username, user.Password);

                driver.With<ImportCasePageObject>(page =>
                {
                    page.Import(invalidcpaxml);

                    Assert.True(page.HasValidationError, "should display invalid as 'Data Input' is not a valid import request type");
                });

                driver.With<ImportCasePageObject>(page =>
                {
                    page.Import(validcpaxml);

                    Assert.False(page.HasValidationError, "should not display validation error as the cpaxml should pass");

                    page.LevelUpButton.ClickWithTimeout();

                    var url = driver.WithJs().GetUrl();

                    Assert.True(url.Contains("/#/bulkcaseimport"), $"should display imported batch, but went to {url} instead.");
                });

                var batch = ImportCaseDbSetup.LastImported();

                Assert.AreEqual("validcpaxml.xml", batch.SenderFileName.ToLower(), "should be the imported file name.");
                Assert.AreEqual("MYAC", batch.Sender, "should be 'MYAC'.");
                Assert.AreEqual("Case Import", batch.SenderRequestType, "should be 'Case Import'.");
                Assert.AreEqual("E2E Batch - importxml", batch.SenderRequestIdentifier, "should be 'E2E Batch - importxml'.");
            }
        }

        [TestFixture]
        [Category(Categories.E2E)]
        public class BasicCsv : ImportCases
        {
            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            public void ImportBasicCsv(BrowserType browserType)
            {
                var driver = BrowserProvider.Get(browserType);

                var invalidCsv = CreateFile("caseImportInvalid.csv");

                var validCsvBasic = CreateFile("Agent Input~E2EAIName~E2EBatchValid.csv");
                NameAlias na;
                using (var db = new ImportCaseDbSetup())
                {
                    na = db.CreateNameWithEdeIdentifier("E2EAIName");
                }

                var user = new Users().WithPermission(ApplicationTask.BulkCaseImport).Create();

                SignIn(driver, "/#/bulkcaseimport/import", user.Username, user.Password);

                driver.With<ImportCasePageObject>(page =>
                {
                    page.Import(invalidCsv);

                    Assert.True(page.HasValidationError, "should display invalid as 'Data Input' is not a valid import request type");
                });

                driver.With<ImportCasePageObject>(page =>
                {
                    page.Import(validCsvBasic);

                    Assert.False(page.HasValidationError, "should not display validation error as the csv should pass");

                    page.LevelUpButton.ClickWithTimeout();

                    var url = driver.WithJs().GetUrl();

                    Assert.True(url.Contains("/#/bulkcaseimport"), $"should display imported batch, but went to {url} instead.");
                });

                var batch = ImportCaseDbSetup.LastImported();

                Assert.AreEqual("agent input~e2eainame~e2ebatchvalid.xml", batch.SenderFileName.ToLower(), "should be the imported file name.");
                Assert.AreEqual(na.Alias, batch.Sender, $"should be '{na.Alias}', this is picked from the file name for Agent Input type csv imports.");
                Assert.AreEqual("Agent Input", batch.SenderRequestType, "should be 'Case Import'.");
                Assert.AreEqual("E2EBatchValid", batch.SenderRequestIdentifier, "should be same as filename 'E2EBatchValid'.");

                var caseDetails = XElement.Parse((string) batch.CpaXml).Descendants("CaseDetails").First();

                Assert.AreEqual("Patent", (string) caseDetails.Element("CasePropertyTypeCode"), "should have CasePropertyTypeCode as 'Patent'");
                Assert.AreEqual("Normal", (string) caseDetails.Element("CaseCategoryCode"), "should have CaseCategoryCode as 'Normal'");
                Assert.AreEqual("Normal", (string) caseDetails.Element("CaseSubTypeCode"), "should have CaseSubTypeCode as 'Normal'");
                Assert.AreEqual("AU", (string) caseDetails.Element("CaseCountryCode"), "should have CaseCountryCode as 'AU'");
                Assert.AreEqual("Sydney Office", (string) caseDetails.Element("CaseOffice"), "should have CaseOffice as 'Sydney Office'");
                Assert.AreEqual("HYDROSIM", (string) caseDetails.Element("Family"), "should have Family as 'HYDROSIM'");
                Assert.AreEqual("Opposition", (string) caseDetails.Element("CaseTypeCode"), "should have case type as 'Opposition'");
            }
        }

        [TestFixture]
        [Category(Categories.E2E)]
        public class ImportCasesCustomColumns : ImportCases
        {
            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            public void ImportCsvWithCustomColumns(BrowserType browserType)
            {
                var driver = BrowserProvider.Get(browserType);

                var validCsvCustomColumns = CreateFile("E2EBatchCustomColumns.csv");

                var user = new Users().WithPermission(ApplicationTask.BulkCaseImport).Create();

                SignIn(driver, "/#/bulkcaseimport/import", user.Username, user.Password);

                DbSetup.Do(x =>
                {
                    const int ede = (int) KnownExternalSystemIds.Ede;

                    var nt = RandomString.Next(5);

                    x.Insert(new Mapping {DataSourceId = ede, StructureId = KnownMapStructures.Events, InputCode = "E2E_Custom_Event"});
                    x.Insert(new Mapping {DataSourceId = ede, StructureId = KnownMapStructures.NameType, InputCode = "E2E_Custom_Name", OutputValue = nt});
                    x.Insert(new Mapping {DataSourceId = ede, StructureId = KnownMapStructures.NumberType, InputCode = "E2E_Custom_Number"});
                    x.Insert(new Mapping {DataSourceId = ede, StructureId = KnownMapStructures.TextType, InputCode = "E2E_Custom_Text"});

                    return nt;
                });

                driver.With<ImportCasePageObject>(page =>
                {
                    page.Import(validCsvCustomColumns);

                    Assert.False(page.HasValidationError, "should not display validation error as the csv should pass");

                    page.LevelUpButton.ClickWithTimeout();

                    var url = driver.WithJs().GetUrl();

                    Assert.True(url.Contains("/#/bulkcaseimport"), $"should display imported batch, but went to {url} instead.");
                });

                var batch = ImportCaseDbSetup.LastImported();

                Assert.AreEqual("e2ebatchcustomcolumns.xml", batch.SenderFileName.ToLower(), "should be the imported file name.");

                Assert.IsTrue(batch.CpaXml.IndexOf("E2E_Custom_Event") > -1, "should have 'E2E_Custom_Event' in the generated cpaxml");
                Assert.IsTrue(batch.CpaXml.IndexOf("E2E_Custom_Name") > -1, "should have 'E2E_Custom_Name' in the generated cpaxml");
                Assert.IsTrue(batch.CpaXml.IndexOf("E2E_Custom_Number") > -1, "should have 'E2E_Custom_Number' in the generated cpaxml");
                Assert.IsTrue(batch.CpaXml.IndexOf("E2E_Custom_Text") > -1, "should have 'E2E_Custom_Text' in the generated cpaxml");
            }

            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            public void ImportCsvWithCustomColumnsWithSpaces(BrowserType browserType)
            {
                var driver = BrowserProvider.Get(browserType);

                var csv = CreateFile("E2EBatchValidWithSpaces.csv");

                var user = new Users().WithPermission(ApplicationTask.BulkCaseImport).Create();

                SignIn(driver, "/#/bulkcaseimport/import", user.Username, user.Password);

                DbSetup.Do(x =>
                {
                    const int ede = (int) KnownExternalSystemIds.Ede;

                    var nt = RandomString.Next(5);

                    x.Insert(new Mapping {DataSourceId = ede, StructureId = KnownMapStructures.Events, InputCode = "E2E_Custom_Event"});
                    x.Insert(new Mapping {DataSourceId = ede, StructureId = KnownMapStructures.NameType, InputCode = "E2E_Custom_Name", OutputValue = nt});
                    x.Insert(new Mapping {DataSourceId = ede, StructureId = KnownMapStructures.NumberType, InputCode = "E2E_Custom_Number"});
                    x.Insert(new Mapping {DataSourceId = ede, StructureId = KnownMapStructures.TextType, InputCode = "E2E_Custom_Text"});

                    return nt;
                });

                driver.With<ImportCasePageObject>(page =>
                {
                    page.Import(csv);

                    Assert.False(page.HasValidationError, "should not display validation error as the csv should pass");

                    page.LevelUpButton.ClickWithTimeout();

                    var url = driver.WithJs().GetUrl();

                    Assert.True(url.Contains("/#/bulkcaseimport"), $"should display imported batch, but went to {url} instead.");
                });

                var batch = ImportCaseDbSetup.LastImported();

                Assert.AreEqual("e2ebatchvalidwithspaces.xml", batch.SenderFileName.ToLower(), "should be the imported file name.");

                var caseDetails = XElement.Parse((string) batch.CpaXml).Descendants("CaseDetails").Single();

                Assert.AreEqual("Patent", (string) caseDetails.Element("CasePropertyTypeCode"), "should have CasePropertyTypeCode as 'Patent'");
                Assert.AreEqual("Normal", (string) caseDetails.Element("CaseCategoryCode"), "should have CaseCategoryCode as 'Normal'");
                Assert.AreEqual("Normal", (string) caseDetails.Element("CaseSubTypeCode"), "should have CaseSubTypeCode as 'Normal'");
                Assert.AreEqual("AU", (string) caseDetails.Element("CaseCountryCode"), "should have CaseCountryCodee as 'AU'");

                var descriptionDetails = caseDetails.Element("DescriptionDetails");

                Assert.AreEqual("E2E_Custom_Text", (string) descriptionDetails?.Element("DescriptionCode"), "should have E2E_Custom_Text");
                Assert.AreEqual("text", (string) descriptionDetails?.Element("DescriptionText"), "should have 'text' for E2E_Custom_Text");

                var identifierNumberDetails = caseDetails.Element("IdentifierNumberDetails");

                Assert.AreEqual("E2E_Custom_Number", (string) identifierNumberDetails?.Element("IdentifierNumberCode"), "should have E2E_Custom_Number");
                Assert.AreEqual("123", (string) identifierNumberDetails?.Element("IdentifierNumberText"), "should have '123' for E2E_Custom_Number");

                var eventDetails = caseDetails.Element("EventDetails");

                Assert.AreEqual("E2E_Custom_Event", (string) eventDetails?.Element("EventCode"), "should have E2E_Custom_Event");
                Assert.AreEqual("2015-07-15", (string) eventDetails?.Element("EventDate"), "should have '2015-07-15' for E2E_Custom_Event");

                var nameDetails = caseDetails.Element("NameDetails");
                var name = nameDetails?.Descendants("Name").Single();

                Assert.AreEqual("E2E_Custom_Name", (string) nameDetails?.Element("NameTypeCode"), "should have E2E_Custom_Name");
                Assert.AreEqual("ABCD", (string) name?.Element("ReceiverNameIdentifier"), "should have 'ABCD' for E2E_Custom_Name");
            }
        }

        [TestFixture]
        [Category(Categories.E2E)]
        public class CaseRelationships : ImportCases
        {
            [TestCase(BrowserType.Chrome)]
            [TestCase(BrowserType.Ie)]
            public void ImportCsvWithCaseRelationships(BrowserType browserType)
            {
                var driver = BrowserProvider.Get(browserType);

                var validCsvMultipleRelatedCases = CreateFile("E2EBatchMultipleRelatedCases.csv");

                var user = new Users().WithPermission(ApplicationTask.BulkCaseImport).Create();

                SignIn(driver, "/#/bulkcaseimport/import", user.Username, user.Password);

                driver.With<ImportCasePageObject>(page =>
                {
                    page.Import(validCsvMultipleRelatedCases);

                    Assert.False(page.HasValidationError, "should not display validation error as the csv should pass");

                    page.LevelUpButton.ClickWithTimeout();

                    var url = driver.WithJs().GetUrl();

                    Assert.True(url.Contains("/#/bulkcaseimport"), $"should display imported batch, but went to {url} instead.");

                    driver.Navigate().Back();
                });

                var batch = ImportCaseDbSetup.LastImported();

                Assert.AreEqual("e2ebatchmultiplerelatedcases.xml", batch.SenderFileName.ToLower(), "should be the imported file name.");

                var relatedCasesCount = batch.RelatedCasesCount;

                Assert.AreEqual("2", relatedCasesCount[0].TransactionId);
                Assert.AreEqual(3, relatedCasesCount[0].RelatedCasesCount);

                Assert.AreEqual("3", relatedCasesCount[1].TransactionId);
                Assert.AreEqual(2, relatedCasesCount[1].RelatedCasesCount);

                Assert.AreEqual("4", relatedCasesCount[2].TransactionId);
                Assert.AreEqual(2, relatedCasesCount[2].RelatedCasesCount);
            }
        }

        string CreateFile(string file)
        {
            var filePath = FileSetup.MakeAvailable(file);

            _filesAdded.Add(filePath);

            return filePath;
        }
    }
}