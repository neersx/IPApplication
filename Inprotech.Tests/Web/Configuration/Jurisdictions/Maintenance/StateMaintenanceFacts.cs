using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Configuration.Jurisdictions;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions.Maintenance
{
    public class StateMaintenanceFacts
    {
        public const string TopicName = "states";
        const string CountryCode = "AF";
        const string StateName = "State 01";
        const string State1 = "01";
        const string State2 = "02";

        public class StateMaintenanceFixture : IFixture<StateMaintenance>
        {
            readonly InMemoryDbContext _db;

            public StateMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new StateMaintenance(db);
            }

            public StateMaintenance Subject { get; set; }

            public State PrepareData()
            {
                var country = new CountryBuilder {Id = CountryCode}.Build().In(_db);
                return new State(State1, StateName, country).In(_db);
            }
        }

        public class ValidateMethod : FactBase
        {
            [Fact]
            public void ShouldGiveDuplicateStateErrorOnValidate()
            {
                var f = new StateMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<StateMaintenanceModel>();

                delta.Added.Add(new StateMaintenanceModel {CountryId = CountryCode, Code = State1, Name = StateName});

                var errors = f.Subject.Validate(delta).ToArray();

                Assert.True(errors.Length == 1);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Duplicate State Code.");
            }

            [Fact]
            public void ShouldGiveRequiredFieldMessageIfMandatoryStateCodeNotProvided()
            {
                var f = new StateMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<StateMaintenanceModel>();

                delta.Added.Add(new StateMaintenanceModel {CountryId = CountryCode, Name = StateName});

                var errors = f.Subject.Validate(delta).ToArray();

                Assert.True(errors.Length == 1);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Mandatory field State Code was empty.");
            }

            [Fact]
            public void ShouldGiveRequiredFieldMessageIfMandatoryStateNameNotProvided()
            {
                var f = new StateMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<StateMaintenanceModel>();

                delta.Added.Add(new StateMaintenanceModel {CountryId = CountryCode, Code = State2});

                var errors = f.Subject.Validate(delta).ToArray();

                Assert.True(errors.Length == 1);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Mandatory field State Name was empty.");
            }
        }

        public class SaveUpdateMethod : FactBase
        {
            [Fact]
            public void ShouldAddState()
            {
                var f = new StateMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<StateMaintenanceModel>();
                delta.Added.Add(new StateMaintenanceModel
                {
                    CountryId = CountryCode,
                    Name = StateName,
                    Code = State2
                });
                f.Subject.Save(delta);

                var totalStates = Db.Set<State>().Where(_ => _.CountryCode == CountryCode).ToList();
                Assert.Equal(2, totalStates.Count);

                var countryState = Db.Set<State>().First(_ => _.Code == State2 && _.CountryCode == CountryCode);

                Assert.Equal(countryState.CountryCode, CountryCode);
                Assert.Equal(countryState.Code, State2);
                Assert.Equal(countryState.Name, StateName);
            }

            [Fact]
            public void ShouldDeleteExistingState()
            {
                var f = new StateMaintenanceFixture(Db);
                var state = f.PrepareData();

                var delta = new Delta<StateMaintenanceModel>();
                delta.Deleted.Add(new StateMaintenanceModel {Id = state.Id, CountryId = state.CountryCode});
                f.Subject.Save(delta);

                var totalTableState = Db.Set<State>().ToList();
                Assert.Empty(totalTableState);
            }

            [Fact]
            public void ShouldNotDeleteInUseGroupMembership()
            {
                var f = new StateMaintenanceFixture(Db);

                var stateDelta = new Delta<StateMaintenanceModel>();

                new AddressBuilder
                {
                    City = "Kabul",
                    Street1 = "Kabul Street",
                    PostCode = "2000",
                    State = "TEST",
                    Country = new CountryBuilder
                    {
                        Name = "Afganistan"
                    }.Build()
                }.Build().In(Db);

                stateDelta.Deleted.Add(new StateMaintenanceModel {CountryId = CountryCode, Code = "TEST"});

                var formData = new JurisdictionModel {Id = CountryCode, Name = Fixture.String(), Type = "0", StateDelta = stateDelta};

                var response = f.Subject.Save(formData.StateDelta);

                Assert.Single(response.InUseItems);
                Assert.Equal("states", response.TopicName);
                Assert.Equal(response.InUseItems[0].Code, "TEST");
            }

            [Fact]
            public void ShouldUpdateState()
            {
                var f = new StateMaintenanceFixture(Db);
                var state = f.PrepareData();

                var delta = new Delta<StateMaintenanceModel>();
                delta.Updated.Add(new StateMaintenanceModel
                {
                    Id = state.Id,
                    CountryId = state.CountryCode,
                    Name = "Updated State"
                });
                f.Subject.Save(delta);
                var countryState = Db.Set<State>().First(_ => _.Id == state.Id && _.CountryCode == state.CountryCode);

                Assert.NotNull(countryState);

                Assert.Equal(countryState.CountryCode, CountryCode);
                Assert.Equal("Updated State", countryState.Name);
            }
        }
    }
}