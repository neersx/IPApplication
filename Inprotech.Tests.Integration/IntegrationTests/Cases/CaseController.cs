using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json.Linq;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Cases
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class CaseController : IntegrationTest
    {
        [TearDown]
        public void CleanupModifiedData()
        {
            SiteControlRestore.ToDefault(SiteControls.CriticalDates_Internal);
        }

        static void AssertName(string nameType, IEnumerable<CaseName> caseNames, IEnumerable<JToken> jsonNames)
        {
            var formattedName = caseNames.Single(_ => _.NameTypeId == nameType).Name.FormattedNameOrNull();
            var result = (string) jsonNames.Single(_ => (string) _["nameTypeKey"] == nameType)["name"];

            Assert.AreEqual(formattedName, result, $"Should have name type {nameType} '{formattedName}', but got '{result}'");
        }

        [Test]
        public void GetSummary()
        {
            var data = DbSetup.Do(setup =>
            {
                var d = new CaseBuilder(setup.DbContext).CreateWithSummaryData();

                var cd = new CaseDetailsDbSetup(setup.DbContext).CriticalDatesAndEventsSetup(d.Case);

                var instuctionReceivedDate = d.Case
                                              .CaseEvents
                                              .Single(_ => _.EventNo == (int) KnownEvents.InstructionsReceivedDateForNewCase && _.Cycle == 1);

                var nextRenewalDueDate = d.Case
                                          .CaseEvents
                                          .Single(_ => _.EventNo == (int) KnownEvents.NextRenewalDate);
                nextRenewalDueDate.EventDueDate = DateTime.Today.AddYears(-3);
                setup.DbContext.SaveChanges();

                return new
                {
                    d.Case,
                    DateOfInstructions = instuctionReceivedDate.EventDate,
                    d.RenewalStatus,
                    d.RenewalInstruction,
                    NextRenewalDue = nextRenewalDueDate.EventDueDate,
                    cd[d.Case].CriticalDates.Row1,
                    cd[d.Case].CriticalDates.Row2
                };
            });

            var result = ApiClient.Get<JObject>($"search/case/{data.Case.Id}/searchsummary");

            var caseData = result["caseData"];
            Assert.AreEqual(data.Case.Id.ToString(), (string) caseData["caseKey"], "Should have the same caseKey");
            Assert.AreEqual(data.Case.Irn, (string) caseData["irn"], "Should have the same irn");
            Assert.AreEqual(data.Case.Title, (string) caseData["title"], "Should have the same title");
            Assert.AreEqual(data.Case.CaseStatus.Name, (string) caseData["caseStatusDescription"], "Should have the same case status description");
            Assert.AreEqual(data.RenewalStatus, (string) caseData["renewalStatusDescription"], "Should have the same renewal status description");
            Assert.AreEqual(data.RenewalInstruction, (string) caseData["renewalInstruction"], "Should have the same renewal instruction");

            Assert.AreEqual(data.Case.Country.Name, (string) caseData["countryName"], "Should have the same country name");
            Assert.AreEqual(data.Case.Type.Name, (string) caseData["caseTypeDescription"], "Should have the same case type description");
            Assert.AreEqual("v" + data.Case.PropertyType.Name, (string) caseData["propertyTypeDescription"], "Should have the sam Valid Property");
            Assert.AreEqual("v" + data.Case.Category.Name, (string) caseData["caseCategoryDescription"], "Should have the same Valid Category");
            Assert.AreEqual("v" + data.Case.SubType.Name, (string) caseData["subTypeDescription"], "Should have the same Valid SubType");

            Assert.AreEqual(data.Case.CaseLocations.First().FileLocation.Name, (string) caseData["fileLocation"], "Should have the same file location");
            Assert.AreEqual(data.Case.Office.Name, (string) caseData["caseOffice"], "Should have the same case office");

            Assert.AreEqual(data.Case.CaseImages.First().ImageId.ToString(), caseData["imageKey"].ToString(), "Should have the same case header image");

            var names = result["names"];
            AssertName(KnownNameTypes.Instructor, data.Case.CaseNames, names);
            AssertName(KnownNameTypes.Owner, data.Case.CaseNames, names);
            AssertName(KnownNameTypes.Signatory, data.Case.CaseNames, names);
            AssertName(KnownNameTypes.StaffMember, data.Case.CaseNames, names);

            var dates = result["dates"];

            Assert.AreEqual(data.Row1.EventDescription, (string) dates[0]["eventDescription"], "Should have the same earliest priority event description");
            Assert.AreEqual(data.Row1.PriorityNumber, (string) dates[0]["officialNumber"], "Should have the same earliest priority number");
            Assert.AreEqual(data.Row1.PriorityCountry, (string) dates[0]["countryCode"], "Should have the same country code");
            Assert.AreEqual(data.Row1.PriorityDate, ((DateTime) dates[0]["date"]).ToString("dd-MMM-yyyy"), "Should have the same priority date");

            Assert.AreEqual(data.Row2.EventDescription, (string) dates[1]["eventDescription"], "Should have the same critical event description");
            Assert.AreEqual(data.Row2.EventDate, ((DateTime) dates[1]["date"]).ToString("dd-MMM-yyyy"), "Should have the same critical date");

            Assert.AreEqual(data.NextRenewalDue, (DateTime) dates[2]["date"], "Should return next renewal due date");
            Assert.IsFalse((bool) dates[2]["isOccurred"], "Should indicate next renewal due date as have not occurred");
            Assert.IsTrue((bool) dates[2]["isNextDueEvent"], "Should indicate next renewal due date as the next due event");
        }

        [Test]
        public void GetActionEventNotesExternal()
        {
            var user = new Users().CreateExternalUser();
            new CaseDetailsActionsDbSetup()
                .SetSiteControlForClientNote(true)
                .SetGlobalPreferenceForNoteType(null);

            new CaseDetailsActionsDbSetup().SetGlobalPreferenceForNoteType(82);
            var data = new CaseDetailsActionsDbSetup().ActionsSetupExternal(user.Id);

            var result = ApiClient.GetExternal<JObject>($"case/{data.CaseId}/action/{data.OpenActionWithMultipleEvents.Va.ActionId}" + "?q={" +
                                                        "cycle:1" +
                                                        ",criteriaId:'" + data.Criteria.Id + "'" +
                                                        ",importanceLevel:1" +
                                                        ",isCyclic:true" +
                                                        ",AllEvents:true" +
                                                        ",MostRecent:true" +
                                                        "}&params={skip:0,take:20}", user.Username, user.Id);

            var note = result["data"][1]["eventNotes"][0];
            Assert.AreNotEqual(note["isDefault"], true, "Notetype is becoming default when global preference set");
        }

        [Test]
        public void GetActionEventNotesInternal()
        {
            var data = new CaseDetailsActionsDbSetup().ActionsSetup();

            var result = GetResponse(data.CaseId, data.OpenActionWithMultipleEvents.Va.ActionId, data.Criteria.Id);

            var resultData = result["data"][0];
            Assert.AreNotEqual(resultData, null, "result set Shouldn't be null");
            var notesNullType = resultData["eventNotes"][1];

            Assert.AreNotEqual(notesNullType["isDefault"], true, "null type is becoming default when no preference set");

            new CaseDetailsActionsDbSetup().SetGlobalPreferenceForNoteType(1);
            result = GetResponse(data.CaseId, data.OpenActionWithMultipleEvents.Va.ActionId, data.Criteria.Id);

            notesNullType = result["data"][0]["eventNotes"][0];

            Assert.AreNotEqual(notesNullType["isDefault"], true, "type 1 is becoming default when global preference set");

            new CaseDetailsActionsDbSetup().SetUserPreferenceForNoteType(Env.LoginUsername, null);
            result = GetResponse(data.CaseId, data.OpenActionWithMultipleEvents.Va.ActionId, data.Criteria.Id);

            notesNullType = result["data"][0]["eventNotes"][1];
            Assert.AreNotEqual(notesNullType["isDefault"], true, "type 1 is becoming default when user preference set");
        }

        [Test]
        public void GetExternalOverview()
        {
            var data = DbSetup.Do(setup =>
            {
                var clientReference = Fixture.String(10);
                var d = new CaseBuilder(setup.DbContext).CreateWithSummaryData(null, true);
                var mainContact = new NameBuilder(setup.DbContext).Create();
                var user = setup.DbContext.Set<User>().Single(v => v.Id == d.User.Id);
                var newInstructor = new NameBuilder(setup.DbContext).Create();
                var accessName = user.AccessAccount;
                setup.Insert(new AccessAccountName {AccessAccountId = accessName.Id, NameId = newInstructor.Id});
                newInstructor.MainContact = mainContact;

                var i = d.Case.CaseNames.Single(v => v.NameTypeId == KnownNameTypes.Instructor);
                d.Case.CaseNames.Remove(i);

                d.Case.CaseNames.Add(new CaseName(d.Case, i.NameType, newInstructor, i.Sequence){Reference = clientReference });
                
                user.Name = newInstructor;

                var firmContact = d.Case.CaseNames.First(v => v.NameTypeId == KnownNameTypes.Signatory);

                setup.DbContext.SaveChanges();

                return new
                {
                    d.Case,
                    d.User,
                    Instructor = newInstructor,
                    FirmContact = firmContact,
                    Reference = clientReference
                };
            });

            var result = ApiClient.GetExternal<JObject>($"case/{data.Case.Id}/overview", data.User.Username, data.User.Id);

            var reference = result["yourReference"];
            var clientMainContact = result["clientMainContact"];
            var ourContact = result["ourContact"];

            Assert.AreEqual(reference.ToString(), data.Reference, "References should be the same.");
            Assert.AreEqual((int)clientMainContact["nameKey"], data.Instructor.MainContact.Id, "ClientMainContact should be the same.");
            Assert.AreEqual((int)ourContact["nameKey"], data.FirmContact.Name.Id, "OurContact should be the same.");
        }

        JObject GetResponse(int caseId, string actionId, int criteriaId)
        {
            return ApiClient.Get<JObject>($"case/{caseId}/action/{actionId}" + "?q={" +
                                          "cycle:1" +
                                          ",criteriaId:'" + criteriaId + "'" +
                                          ",importanceLevel:1" +
                                          ",isCyclic:true" +
                                          ",AllEvents:false" +
                                          ",MostRecent:true" +
                                          "}&params={skip:0,take:20}");
        }
    }
}