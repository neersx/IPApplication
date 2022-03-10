using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration.KeepOnTopNotes;
using InprotechKaizen.Model.Names;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.KeepOnTopNotes
{
    [Category(Categories.Integration)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    public class KeepOnTopNotes16 : IntegrationTest
    {
        [Test]
        public void KeepOnTopNotesForCase()
        {
            var dbData = DbSetup.Do(x =>
            {
                var caseBuilder = new CaseBuilder(x.DbContext);
                var @case = caseBuilder.Create("e2e", null);
                var tt1 = x.Insert(new TextType { Id = "EE", TextDescription = "E2E Test" });
                var kot1 = x.InsertWithNewId(new KeepOnTopTextType { TextTypeId = tt1?.Id, TextType = tt1, CaseProgram = true, NameProgram = false, TimeProgram = false, IsRegistered = false, IsPending = false, IsDead = false, Type = KnownKotTypes.Case, BackgroundColor = "#ffffff" });
                var kotCt1 = x.Insert(new KeepOnTopCaseType { CaseTypeId = @case.Type.Code, CaseType = @case.Type, KotTextTypeId = kot1.Id, KotTextType = kot1 });
                kot1.KotCaseTypes = new List<KeepOnTopCaseType>
                {
                    kotCt1
                };

                x.Insert(new CaseText(@case.Id, tt1?.Id, 0, null)
                {
                    Language = null,
                    Text = "Case Text",
                    TextType = tt1
                });
                x.DbContext.SaveChanges();

                return new { @case, kot1, tt1 };
            });
            var result = ApiClient.Get<JObject>($"keepontopnotes/{dbData.@case.Id}/Case");
            var data = result.ContainsKey("result") ? result["result"] : null;

            DbSetup.Do(x =>
            {
                Assert.NotNull(data);
                Assert.NotNull(data.Any());
                Assert.AreEqual(dbData.@case.Irn, (string)data[0]["caseRef"], "Should have the same case Reference");
                Assert.AreEqual(dbData.@case.CaseTexts.FirstOrDefault()?.Text, (string)data[0]["note"], "Should have the same Note");
                Assert.AreEqual(dbData.tt1.TextDescription, (string)data[0]["textType"], "Should have the same Text Type");
            });
        }

        [Test]
        public void KeepOnTopNotesForCaseNames()
        {
            var dbData = DbSetup.Do(x =>
            {
                var caseBuilder = new CaseBuilder(x.DbContext);
                var @case = caseBuilder.Create("e2e", null);
                var debtor = x.DbContext.Set<CaseName>().Single(_ => _.NameTypeId == "D" && _.CaseId == @case.Id);
                var ttn1 = x.DbContext.Set<TextType>().FirstOrDefault(_ => _.Id != "A");

                var kotn1 = x.InsertWithNewId(new KeepOnTopTextType { TextTypeId = ttn1?.Id, TextType = ttn1, CaseProgram = true, NameProgram = true, TimeProgram = false, IsRegistered = false, IsPending = false, IsDead = false, Type = KnownKotTypes.Name, BackgroundColor = "#b9d87b" });
                var kotCt1 = x.Insert(new KeepOnTopCaseType { CaseTypeId = @case.Type.Code, CaseType = @case.Type, KotTextTypeId = kotn1.Id, KotTextType = kotn1 });
                var kotNt1 = x.Insert(new KeepOnTopNameType { NameTypeId = debtor.NameType.NameTypeCode, NameType = debtor.NameType, KotTextTypeId = kotn1.Id, KotTextType = kotn1 });
                kotn1.KotCaseTypes = new List<KeepOnTopCaseType>
                {
                    kotCt1
                };
                @case.Type.TextType = ttn1;
                kotn1.KotNameTypes = new List<KeepOnTopNameType>
                {
                    kotNt1
                };
                var nameText = x.Insert(new NameText
                {
                    Id = debtor.Name.Id,
                    Text = "First Name",
                    TextType = kotn1.TextTypeId
                });
                x.DbContext.SaveChanges();

                return new { debtor, @case, kotn1, nameText };
            });

            var result = ApiClient.Get<JObject>($"keepontopnotes/{dbData.@case.Id}/Case");
            var data = result.ContainsKey("result") ? result["result"] : null;

            DbSetup.Do(x =>
            {
                Assert.NotNull(data.Any());
                Assert.AreEqual(dbData.debtor.NameId, (int)data[0]["nameId"], "Should have the same NameId");
                Assert.AreEqual(dbData.nameText.Text, (string)data[0]["note"], "Should have the same Note");
                Assert.AreEqual(dbData.debtor.Name.FormattedNameOrNull(), (string)data[0]["name"], "Should have the same Name");
                Assert.AreEqual(dbData.debtor.NameType.Name, (string)data[0]["nameTypes"], "Should have the same Name Type");
                Assert.AreEqual(dbData.@case.Type.TextType.TextDescription, (string)data[0]["textType"], "Should have the same Text Type");
            });
        }

        [Test]
        public void KeepOnTopNotesForNameOnly()
        {
            var dbData = DbSetup.Do(x =>
            {
                var caseBuilder = new CaseBuilder(x.DbContext);
                var @case = caseBuilder.Create("e2e", null);
                var caseName = x.DbContext.Set<CaseName>().Single(_ => _.NameTypeId == "D" && _.CaseId == @case.Id);
                var name = x.DbContext.Set<Name>().FirstOrDefault(_ => _.Id == caseName.NameId);
                var ttn1 = x.DbContext.Set<TextType>().FirstOrDefault(_ => _.Id != "A");

                var kot1 = x.InsertWithNewId(new KeepOnTopTextType { TextTypeId = ttn1?.Id, TextType = ttn1, CaseProgram = true, NameProgram = true, TimeProgram = false, IsRegistered = false, IsPending = false, IsDead = false, Type = KnownKotTypes.Name, BackgroundColor = "#b9d87b" });
                var kotNt1 = x.Insert(new KeepOnTopNameType { NameTypeId = caseName.NameType.NameTypeCode, NameType = caseName.NameType, KotTextTypeId = kot1.Id, KotTextType = kot1 });

                kot1.KotNameTypes = new List<KeepOnTopNameType>
                {
                    kotNt1
                };
                var nameText = x.Insert(new NameText
                {
                    Id = caseName.Name.Id,
                    Text = "First Name",
                    TextType = kot1.TextTypeId
                });
                x.DbContext.SaveChanges();

                return new { caseName, name, kot1, nameText };
            });

            var result = ApiClient.Get<JObject>($"keepontopnotes/name/{dbData.caseName.Name.Id}/Case");
            var data = result.ContainsKey("result") ? result["result"] : null;

            DbSetup.Do(x =>
            {
                Assert.NotNull(data.Any());
                Assert.AreEqual(dbData.name.Id, (int)data[0]["nameId"], "Should have the same NameId");
                Assert.AreEqual(dbData.nameText.Text, (string)data[0]["note"], "Should have the same Note");
                Assert.AreEqual(dbData.caseName.Name.FormattedNameOrNull(), (string)data[0]["name"], "Should have the same Name");
                Assert.AreEqual(dbData.caseName.NameType.Name, (string)data[0]["nameTypes"], "Should have the same Name Type");
                Assert.AreEqual(dbData.kot1.TextType.TextDescription, (string)data[0]["textType"], "Should have the same Kot Text Type");
            });
        }
    }
}