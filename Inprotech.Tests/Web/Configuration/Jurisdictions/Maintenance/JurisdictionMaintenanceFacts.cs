using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Configuration.Jurisdictions;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions.Maintenance
{
    public class JurisdictionMaintenanceFacts
    {
        public class JurisdictionMaintenanceFixture : IFixture<JurisdictionMaintenance>
        {
            public JurisdictionMaintenanceFixture(InMemoryDbContext db)
            {
                GroupMembershipMaintenance = Substitute.For<IGroupMembershipMaintenance>();
                OverviewMaintenance = Substitute.For<IOverviewMaintenance>();
                JurisdictionMaintenance = Substitute.For<IJurisdictionMaintenance>();
                TextsMaintenance = Substitute.For<ITextsMaintenance>();
                AttributesMaintenance = Substitute.For<IAttributesMaintenance>();
                StatusFlagsMaintenance = Substitute.For<IStatusFlagsMaintenance>();
                ClassesMaintenance = Substitute.For<IClassesMaintenance>();
                StateMaintenance = Substitute.For<IStateMaintenance>();
                CountryHolidayMaintenance = Substitute.For<ICountryHolidayMaintenance>();
                ValidNumbersMaintenance = Substitute.For<IValidNumbersMaintenance>();
                Subject = new JurisdictionMaintenance(db, GroupMembershipMaintenance, OverviewMaintenance, AttributesMaintenance, TextsMaintenance, StatusFlagsMaintenance, ClassesMaintenance, StateMaintenance, CountryHolidayMaintenance, ValidNumbersMaintenance);
            }

            public IGroupMembershipMaintenance GroupMembershipMaintenance { get; set; }
            public IOverviewMaintenance OverviewMaintenance { get; set; }
            public IJurisdictionMaintenance JurisdictionMaintenance { get; set; }
            public ITextsMaintenance TextsMaintenance { get; set; }
            public IAttributesMaintenance AttributesMaintenance { get; set; }
            public IStatusFlagsMaintenance StatusFlagsMaintenance { get; set; }
            public IClassesMaintenance ClassesMaintenance { get; set; }
            public IStateMaintenance StateMaintenance { get; set; }
            public IValidNumbersMaintenance ValidNumbersMaintenance { get; set; }
            public ICountryHolidayMaintenance CountryHolidayMaintenance { get; set; }
            public JurisdictionMaintenance Subject { get; set; }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesOnlyyTheSpecifiedCountries()
            {
                const string countryCode = "XYZ";
                var f = new JurisdictionMaintenanceFixture(Db);
                new Country(countryCode, Fixture.String(countryCode), "0").In(Db);
                new Country("ABC", Fixture.String(countryCode), "0").In(Db);
                new Country("DEF", Fixture.String(countryCode), "0").In(Db);

                f.Subject.Delete(new[] {"XYZ"});
                Assert.False(Db.Set<Country>().Any(_ => _.Id == "XYZ"));
                Assert.True(Db.Set<Country>().Any(_ => _.Id == "ABC"));
                Assert.True(Db.Set<Country>().Any(_ => _.Id == "DEF"));
            }
        }

        public class Maintenance : FactBase
        {
            [Fact]
            public void CallSaveWithDeletedInUseItemsReturnsInUseInResultWhenResponseModelReturnsInUse()
            {
                var result = new {Result = "success"};
                var f = new JurisdictionMaintenanceFixture(Db);
                var stateModel = new Delta<StateMaintenanceModel>();
                var smm = new StateMaintenanceModel {CountryId = "XYZ", Code = "TEST"};
                stateModel.Deleted.Add(smm);
                f.JurisdictionMaintenance.Save(Arg.Any<JurisdictionModel>(), Operation.Add).Returns(result);
                f.StateMaintenance.Save(Arg.Any<Delta<StateMaintenanceModel>>()).Returns(new JurisdictionSaveResponseModel {InUseItems = new List<StateMaintenanceModel> {smm}, TopicName = "states"});
                var formData = new JurisdictionModel {Id = Fixture.String(), Name = Fixture.String(), Type = Fixture.String(), StateDelta = stateModel};
                var output = f.Subject.Save(formData, Operation.Add);

                Assert.Equal(result.Result, output.Result);
                Assert.Equal(true, output.HasInUseItems);
                Assert.Equal(1, output.SaveResponse[0].InUseItems.Count);
                Assert.Equal("states", output.SaveResponse[0].TopicName);
            }

            [Fact]
            public void CallsSave()
            {
                var countryCode = Fixture.String().Substring(0, 3);

                var f = new JurisdictionMaintenanceFixture(Db);
                var groupMembership = new Delta<GroupMembershipModel>();
                groupMembership.Added.Add(new GroupMembershipModel {GroupCode = "TT", MemberCode = countryCode});

                var formData = new JurisdictionModel {Id = countryCode, Name = Fixture.String(), Type = Fixture.String(), GroupMembershipDelta = groupMembership};
                f.Subject.Save(formData, Operation.Add);
                f.GroupMembershipMaintenance.Received(1).Save(formData.GroupMembershipDelta);
                f.OverviewMaintenance.Received(1).Save(formData, Operation.Add);
            }

            [Fact]
            public void CallsSaveAsAddAndReturnsResult()
            {
                var countryCode = Fixture.String().Substring(0, 3);

                var result = new {Result = "success"};
                var f = new JurisdictionMaintenanceFixture(Db);
                var groupMembership = new Delta<GroupMembershipModel>();
                groupMembership.Added.Add(new GroupMembershipModel {GroupCode = "TT", MemberCode = countryCode});
                var formData = new JurisdictionModel {Id = Fixture.String(), Name = Fixture.String(), Type = Fixture.String(), GroupMembershipDelta = groupMembership};
                var output = f.Subject.Save(formData, Operation.Add);
                f.GroupMembershipMaintenance.Received(1).Save(formData.GroupMembershipDelta);
                f.OverviewMaintenance.Received(1).Save(formData, Operation.Add);
                Assert.Equal(result.Result, output.Result);
            }

            [Fact]
            public void UpdateJurisdictionCodeWithExistingCode()
            {
                new Country("YY", Fixture.String("YY"), "0").In(Db);
                var data = new ChangeJurisdictionCodeDetails {JurisdictionCode = "XX", NewJurisdictionCode = "YY"};
                var f = new JurisdictionMaintenanceFixture(Db);

                var output = f.Subject.UpdateJurisdictionCode(data);
                Assert.NotNull(output.Errors);
                Assert.Equal(output.Errors[0].Field, "jurisdiction");
                Assert.Equal(output.Errors[0].Message, "field.errors.notunique");
            }
        }
    }
}