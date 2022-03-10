using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.Entries
{
    [Category(Categories.Integration)]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "12.1")]
    [TestFrom(DbCompatLevel.Release14)]
    [TestFixture]
    public class GetEntryControl : IntegrationTest
    {
        [Test]
        public void GetEntryControlData()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = CriteriaTreeBuilder.Build();

                var childTask = f.Child1.DataEntryTasks.First();
                var dx = setup.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == childTask.CriteriaId && _.Id == childTask.Id);

                var parentTask = f.Parent.DataEntryTasks.First(_ => _.CompareDescriptions(childTask.Description));
                var px = setup.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == parentTask.CriteriaId && _.Id == parentTask.Id);

                dx.UserInstruction = Fixture.String(5);
                px.UserInstruction = Fixture.String(5);

                var officialNumberType = setup.InsertWithNewId(new NumberType());
                dx.OfficialNumberTypeId = officialNumberType.NumberTypeCode;
                px.OfficialNumberTypeId = officialNumberType.NumberTypeCode;

                var fileLocation = setup.InsertWithNewId(new TableCode {TableTypeId = (int)TableTypes.FileLocation});
                dx.FileLocationId = fileLocation.Id;
                px.FileLocationId = fileLocation.Id;

                var status = setup.InsertWithNewId(new Status {Name = Fixture.String(5)});
                dx.CaseStatusCodeId = status.Id;
                dx.RenewalStatusId = status.Id;
                px.CaseStatusCodeId = status.Id;
                px.RenewalStatusId = status.Id;

                var @event = new EventBuilder(setup.DbContext).Create();
                var event1 = new EventBuilder(setup.DbContext).Create();
                var event2 = new EventBuilder(setup.DbContext).Create();
                dx.DisplayEventNo = @event.Id;
                dx.HideEventNo = event1.Id;
                dx.DimEventNo = event2.Id;
                px.DisplayEventNo = event2.Id;
                px.HideEventNo = @event.Id;
                px.DimEventNo = event1.Id;

                setup.DbContext.SaveChanges();

                return new
                {
                    Parent = px,
                    Child = dx
                };
            });

            var result = ApiClient.Get<dynamic>("configuration/rules/workflows/" + data.Child.CriteriaId + "/entrycontrol/" + data.Child.Id);

            Assert.AreEqual(data.Child.CriteriaId, result.criteriaId.Value, "Correct criteria id should be returned");
            Assert.AreEqual(data.Child.Id, result.entryId.Value, "Correct entry id should be returned");
            Assert.IsTrue((bool)result.isInherited.Value, "Child entry should be inherited"); 
            CheckEntryControlResult(data.Child, result);
            Assert.IsTrue((bool)result.hasParent.Value);
            Assert.IsFalse((bool)result.hasChildren.Value);
            Assert.IsTrue((bool)result.isInherited.Value);
            Assert.AreEqual("Full", result.inheritanceLevel.Value);
            Assert.IsTrue((bool) result.hasParentEntry.Value);
            Assert.IsTrue((bool) result.showUserAccess.Value);
            Assert.IsNotNull(result.canAddValidCombinations.Value);

            Assert.IsNotNull(result.parent, "Parent event data should be returned");
            Assert.AreEqual(data.Parent.CriteriaId, result.parent.criteriaId.Value, "Correct parent criteria id should be returned");
            Assert.AreEqual(data.Parent.Id, result.parent.entryId.Value, "Correct parent entry id should be returned");
            CheckEntryControlResult(data.Parent, result.parent);
        }

        static void CheckEntryControlResult(DataEntryTask data, dynamic result)
        {
            Assert.AreEqual(data.Description, result.description.Value, "Correct description should be returned");
            Assert.AreEqual(data.UserInstruction, result.userInstruction.Value, "Correct User Instruction should be returned");
            Assert.AreEqual(data.OfficialNumberTypeId, result.officialNumberType.key.Value, "Correct Official number type should be returned");
            Assert.AreEqual(data.FileLocationId, result.fileLocation.key.Value, "Correct File Location should be returned");
            Assert.AreEqual(data.AtLeastOneEventMustBeEntered, (bool) result.atLeastOneEventFlag.Value, "Correct File Location should be returned");
            Assert.AreEqual(data.ShouldPoliceImmediate, (bool) result.policeImmediately.Value, "Correct File Location should be returned");
            Assert.AreEqual(data.CaseStatusCodeId, result.changeCaseStatus.key.Value, "Correct case status should be returned");
            Assert.AreEqual(data.RenewalStatusId, result.changeRenewalStatus.key.Value, "Correct case renewal status should be returned");
            Assert.AreEqual(data.DisplayEventNo, result.displayEvent.key.Value, "Correct display event should be returned");
            Assert.AreEqual(data.HideEventNo, result.hideEvent.key.Value, "Correct hide event should be returned");
            Assert.AreEqual(data.DimEventNo, result.dimEvent.key.Value, "Correct dim event should be returned");
        }
    }
}
