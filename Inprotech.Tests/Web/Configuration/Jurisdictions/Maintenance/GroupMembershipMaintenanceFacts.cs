using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Jurisdictions;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions.Maintenance
{
    public class GroupMembershipMaintenanceFacts
    {
        public class GroupMembershipMaintenanceFixture : IFixture<GroupMembershipMaintenance>
        {
            public GroupMembershipMaintenanceFixture(InMemoryDbContext db)
            {
                Subject = new GroupMembershipMaintenance(db);
            }

            public GroupMembershipMaintenance Subject { get; set; }
        }

        public class ValidateMethod : FactBase
        {
            const string TopicName = "groups";

            [Fact]
            public void DoesNotAllowAddingDuplicate()
            {
                const string memberCode = "BB";

                var f = new GroupMembershipMaintenanceFixture(Db);
                new Country(memberCode, Fixture.String(memberCode), Fixture.String()).In(Db);
                new CountryGroup("TT", memberCode).In(Db);

                var groupMembership = new Delta<GroupMembershipModel>();

                groupMembership.Added.Add(new GroupMembershipModel {GroupCode = "TT", MemberCode = memberCode});

                var formData = new JurisdictionModel {Id = memberCode, Name = Fixture.String(), Type = "0", GroupMembershipDelta = groupMembership};

                var errors = f.Subject.Validate(formData.GroupMembershipDelta).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == Resources.DuplicateGroupCodeMessage);
            }

            [Fact]
            public void FullMembershipAndAssociateMemberDateShouldNotBeGreaterThanCeasedDate()
            {
                const string countryCode = "BB";

                var f = new GroupMembershipMaintenanceFixture(Db);
                new Country(countryCode, Fixture.String(countryCode), Fixture.String()).In(Db);

                var groupMembership = new Delta<GroupMembershipModel>();

                groupMembership.Added.Add(new GroupMembershipModel {GroupCode = "TT", MemberCode = countryCode, DateCommenced = Fixture.PastDate(), FullMembershipDate = Fixture.PastDate().AddDays(10), AssociateMemberDate = Fixture.PastDate().AddDays(8), DateCeased = Fixture.PastDate().AddDays(5)});

                var formData = new JurisdictionModel {Id = countryCode, Name = Fixture.String(), Type = "0", GroupMembershipDelta = groupMembership};

                var errors = f.Subject.Validate(formData.GroupMembershipDelta).ToArray();

                Assert.Equal(2, errors.Length);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == Resources.DateLeftErrorMessage);
                Assert.Contains(errors, v => v.Message == Resources.DateLeftAssoicateMemberErrorMessage);
            }

            [Fact]
            public void FullMembershipAssociateMemberDateAndCeasedDateShouldNotBeLessThanCommencedDate()
            {
                const string countryCode = "BB";

                var f = new GroupMembershipMaintenanceFixture(Db);
                new Country(countryCode, Fixture.String(countryCode), Fixture.String()).In(Db);

                var groupMembership = new Delta<GroupMembershipModel>();

                groupMembership.Added.Add(new GroupMembershipModel {GroupCode = "TT", MemberCode = countryCode, DateCommenced = Fixture.PastDate(), FullMembershipDate = Fixture.PastDate().AddDays(-10), AssociateMemberDate = Fixture.PastDate().AddDays(-5), DateCeased = Fixture.PastDate().AddDays(-5)});

                var formData = new JurisdictionModel {Id = countryCode, Name = Fixture.String(), Type = "0", GroupMembershipDelta = groupMembership};

                var errors = f.Subject.Validate(formData.GroupMembershipDelta).ToArray();

                Assert.Equal(3, errors.Length);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == Resources.DateCeasedErrorMessage);
                Assert.Contains(errors, v => v.Message == Resources.DateFullMembershipErrorMessage);
                Assert.Contains(errors, v => v.Message == Resources.DateAssociateMemberErrorMessage);
            }

            [Fact]
            public void FullMembershipDateNotBlankForAssociateMember()
            {
                const string countryCode = "BB";

                var f = new GroupMembershipMaintenanceFixture(Db);
                new Country(countryCode, Fixture.String(countryCode), Fixture.String()).In(Db);

                var groupMembership = new Delta<GroupMembershipModel>();

                groupMembership.Added.Add(new GroupMembershipModel {GroupCode = "TT", MemberCode = countryCode, FullMembershipDate = Fixture.PastDate().AddDays(10), IsAssociateMember = true});

                var formData = new JurisdictionModel {Id = countryCode, Name = Fixture.String(), Type = "0", GroupMembershipDelta = groupMembership};

                var errors = f.Subject.Validate(formData.GroupMembershipDelta).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == Resources.AssociateMemberErrorMessage);
            }

            [Fact]
            public void GroupAndCountryCannotBeSame()
            {
                const string countryCode = "BB";

                var f = new GroupMembershipMaintenanceFixture(Db);
                new Country(countryCode, Fixture.String(countryCode), Fixture.String()).In(Db);

                var groupMembership = new Delta<GroupMembershipModel>();

                groupMembership.Added.Add(new GroupMembershipModel {GroupCode = "BB", MemberCode = countryCode});

                var formData = new JurisdictionModel {Id = countryCode, Name = Fixture.String(), Type = "0", GroupMembershipDelta = groupMembership};

                var errors = f.Subject.Validate(formData.GroupMembershipDelta).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == Resources.SameMemberAndGroupCodeMessage);
            }
        }

        public class SaveUpdateMethod : FactBase
        {
            const string MemberCode = "BB";
            const string GroupCode = "EP";

            [Fact]
            public void ShouldDeleteEventControlDesignation()
            {
                var f = new GroupMembershipMaintenanceFixture(Db);
                var country = new Country(GroupCode, Fixture.String(GroupCode), Fixture.String()).In(Db);
                var memberCountry = new Country(MemberCode, Fixture.String(MemberCode), Fixture.String()).In(Db);
                new CountryGroup(GroupCode, MemberCode).In(Db);

                var criteria = new Criteria {Country = country}.In(Db);
                new DueDateCalc(criteria.Id, Fixture.Integer(), Fixture.Short()) {Jurisdiction = memberCountry, Criteria = criteria}.In(Db);

                var groupMembershipDelta = new Delta<GroupMembershipModel>();

                groupMembershipDelta.Deleted.Add(new GroupMembershipModel {GroupCode = GroupCode, MemberCode = MemberCode});

                var formData = new JurisdictionModel {Id = GroupCode, Name = Fixture.String(), Type = "0", GroupMembershipDelta = groupMembershipDelta};

                f.Subject.Save(formData.GroupMembershipDelta);

                var countryGroups = Db.Set<CountryGroup>();
                var dueDateCalc = Db.Set<DueDateCalc>();

                Assert.Empty(countryGroups);
                Assert.Empty(dueDateCalc);
            }

            [Fact]
            public void ShouldDeleteGroupMembership()
            {
                var f = new GroupMembershipMaintenanceFixture(Db);
                new Country(MemberCode, Fixture.String(MemberCode), Fixture.String()).In(Db);
                new CountryGroup(GroupCode, MemberCode).In(Db);

                var groupMembershipDelta = new Delta<GroupMembershipModel>();

                groupMembershipDelta.Deleted.Add(new GroupMembershipModel {GroupCode = GroupCode, MemberCode = MemberCode});

                var formData = new JurisdictionModel {Id = MemberCode, Name = Fixture.String(), Type = "0", GroupMembershipDelta = groupMembershipDelta};

                f.Subject.Save(formData.GroupMembershipDelta);

                var countryGroups = Db.Set<CountryGroup>();

                Assert.Empty(countryGroups);
            }

            [Fact]
            public void ShouldSaveAndUpdateGroupMembership()
            {
                const string updatedMemberCode = "CC";

                var f = new GroupMembershipMaintenanceFixture(Db);
                new Country(MemberCode, Fixture.String(MemberCode), Fixture.String()).In(Db);
                new Country(updatedMemberCode, Fixture.String(updatedMemberCode), Fixture.String()).In(Db);
                new CountryGroup("AF", updatedMemberCode).In(Db);

                var groupMembership = new Delta<GroupMembershipModel>();

                groupMembership.Added.Add(new GroupMembershipModel {GroupCode = "TT", MemberCode = MemberCode, DateCommenced = Fixture.PastDate(), FullMembershipDate = Fixture.PastDate().AddDays(5), DateCeased = Fixture.PastDate().AddDays(10), AssociateMemberDate = Fixture.PastDate().AddDays(20), PropertyTypes = "P,T"});
                groupMembership.Added.Add(new GroupMembershipModel {GroupCode = "MM", MemberCode = MemberCode, DateCommenced = Fixture.PastDate(), FullMembershipDate = Fixture.PastDate().AddDays(5), DateCeased = Fixture.PastDate().AddDays(8), AssociateMemberDate = Fixture.PastDate().AddDays(20), PropertyTypes = "P"});
                groupMembership.Updated.Add(new GroupMembershipModel {GroupCode = "AF", MemberCode = updatedMemberCode, DateCommenced = Fixture.PastDate(), FullMembershipDate = Fixture.PastDate().AddDays(5), AssociateMemberDate = Fixture.PastDate().AddDays(15), DateCeased = Fixture.PastDate().AddDays(10), PropertyTypes = "T"});

                var formData = new JurisdictionModel {Id = MemberCode, Name = Fixture.String(), Type = "0", GroupMembershipDelta = groupMembership};

                f.Subject.Save(formData.GroupMembershipDelta);

                var j = Db.Set<CountryGroup>().Where(_ => _.MemberCountry == "BB").ToArray();

                Assert.Equal(j.Length, formData.GroupMembershipDelta.Added.Count);

                var firstGroup = groupMembership.Added.Single(_ => _.GroupCode == "TT");
                Assert.Equal(j[0].Id, firstGroup.GroupCode);
                Assert.Equal(j[0].MemberCountry, firstGroup.MemberCode);
                Assert.Equal(j[0].DateCommenced, firstGroup.DateCommenced);
                Assert.Equal(j[0].FullMembershipDate, firstGroup.FullMembershipDate);
                Assert.Equal(j[0].AssociateMemberDate, firstGroup.AssociateMemberDate);
                Assert.Equal(j[0].DateCeased, firstGroup.DateCeased);
                Assert.Equal(j[0].PropertyTypes, firstGroup.PropertyTypes);

                var secondGroup = groupMembership.Added.Single(_ => _.GroupCode == "MM");
                Assert.Equal(j[1].Id, secondGroup.GroupCode);
                Assert.Equal(j[1].MemberCountry, secondGroup.MemberCode);
                Assert.Equal(j[1].DateCommenced, secondGroup.DateCommenced);
                Assert.Equal(j[1].FullMembershipDate, secondGroup.FullMembershipDate);
                Assert.Equal(j[1].AssociateMemberDate, secondGroup.AssociateMemberDate);
                Assert.Equal(j[1].DateCeased, secondGroup.DateCeased);
                Assert.Equal(j[1].PropertyTypes, secondGroup.PropertyTypes);

                var i = Db.Set<CountryGroup>().Where(_ => _.MemberCountry == "CC").ToArray();

                Assert.Equal(i.Length, formData.GroupMembershipDelta.Updated.Count);

                var updatedGroup = groupMembership.Updated.Single(_ => _.GroupCode == "AF");
                Assert.Equal(i[0].Id, updatedGroup.GroupCode);
                Assert.Equal(i[0].MemberCountry, updatedGroup.MemberCode);
                Assert.Equal(i[0].DateCommenced, updatedGroup.DateCommenced);
                Assert.Equal(i[0].FullMembershipDate, updatedGroup.FullMembershipDate);
                Assert.Equal(i[0].AssociateMemberDate, updatedGroup.AssociateMemberDate);
                Assert.Equal(i[0].DateCeased, updatedGroup.DateCeased);
                Assert.Equal(i[0].PropertyTypes, updatedGroup.PropertyTypes);
            }
        }
    }
}