using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class NameRestrictionMaintenanceControllerFacts
    {
        public class NameRestrictionMaintenanceControllerFixture : IFixture<NameRestrictionsMaintenanceController>
        {
            public NameRestrictionMaintenanceControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();

                Subject = new NameRestrictionsMaintenanceController(DbContext, PreferredCultureResolver, LastInternalCodeGenerator);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }

            public InMemoryDbContext DbContext { get; }
            public NameRestrictionsMaintenanceController Subject { get; }
        }

        public class SearchMethod : FactBase
        {
            public List<DebtorStatus> PrepareData()
            {
                var nameRestriction1 = new DebtorStatusBuilder {RestrictionAction = KnownDebtorRestrictions.NoRestriction, Status = "Status Ok.", ClearTextPassword = null}.Build().In(Db);
                var nameRestriction2 = new DebtorStatusBuilder {RestrictionAction = KnownDebtorRestrictions.DisplayError, Status = "Display error", ClearTextPassword = null}.Build().In(Db);
                var nameRestriction3 = new DebtorStatusBuilder {RestrictionAction = KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation, Status = "Display warning with password", ClearTextPassword = "1234"}.Build().In(Db);
                var nameRestrictionlist = new List<DebtorStatus> {nameRestriction1, nameRestriction2, nameRestriction3};

                return nameRestrictionlist;
            }

            [Theory]
            [InlineData(0, "status", "information")]
            [InlineData(1, "error", "error")]
            [InlineData(2, "warning", "warning")]
            public void ShouldReturnListOfMatchingNameRestrictionWhenSearchOptionIsProvided(int index, string searchText, string severity)
            {
                var nameRestrictionList = PrepareData();
                var searchOptions = new SearchOptions
                {
                    Text = searchText
                };
                var f = new NameRestrictionMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(searchOptions);
                dynamic nameRestriction = e.SingleOrDefault();
                Assert.NotNull(e);
                Assert.NotNull(nameRestriction);
                Assert.Equal(nameRestrictionList[index].Status, nameRestriction.Description);
                Assert.Equal(severity, nameRestriction.Severity);
            }

            [Fact]
            public void ShouldReturnListOfNameRestrictionsWhenSearchOptionIsNotProvided()
            {
                var nameRestrictionList = PrepareData();
                var f = new NameRestrictionMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(null);
                Assert.NotNull(e);
                Assert.Equal(e.Count(), nameRestrictionList.Count);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ShouldDeleteSuccessfully()
            {
                var model = new DebtorStatusBuilder().Build().In(Db);

                var deleteIds = new List<int> {model.Id};

                var deleteRequestModel = new DeleteRequestModel {Ids = deleteIds};
                var f = new NameRestrictionMaintenanceControllerFixture(Db);
                var r = f.Subject.Delete(deleteRequestModel);

                Assert.False(r.HasError);
                Assert.Empty(r.InUseIds);
                Assert.Empty(Db.Set<DebtorStatus>());
            }
        }

        public class GetNameRestrictionMethod : FactBase
        {
            [Fact]
            public void ShouldReturnNameRestrictionDetails()
            {
                var f = new NameRestrictionMaintenanceControllerFixture(Db);

                var nameRestriction = new DebtorStatusBuilder().Build().In(Db);

                var r = f.Subject.GetNameRestriction(nameRestriction.Id);
                Assert.Equal(nameRestriction.Id, r.Id);
                Assert.Equal(nameRestriction.Status, r.Description);
                Assert.Equal(nameRestriction.RestrictionAction, r.Action);
                Assert.Equal(nameRestriction.ClearTextPassword, r.Password);
            }

            [Fact]
            public void ShouldThrowErrorIfNameRestrictionNotFound()
            {
                var f = new NameRestrictionMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.GetNameRestriction(1));
                Assert.IsType<HttpResponseException>(e);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ShouldCreateNewNameRestrictionWithGivenDetails()
            {
                var f = new NameRestrictionMaintenanceControllerFixture(Db);

                f.LastInternalCodeGenerator.GenerateLastInternalCode(Arg.Any<string>()).Returns(1);
                var saveDetails = new NameRestrictionsSaveDetails
                {
                    Description = "Display Warning",
                    Action = KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation,
                    Password = "1234"
                };
                var result = f.Subject.Save(saveDetails);

                var nameRestriction =
                    Db.Set<DebtorStatus>().FirstOrDefault();

                Assert.NotNull(nameRestriction);
                Assert.Equal(saveDetails.Description, nameRestriction.Status);
                Assert.Equal(saveDetails.Action, nameRestriction.RestrictionAction);
                Assert.Equal(saveDetails.Password, nameRestriction.ClearTextPassword);
                Assert.Equal("success", result.Result);
                Assert.Equal(nameRestriction.Id, result.UpdatedId);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNameRestrictionDescriptionIsGreaterThanFifty()
            {
                var f = new NameRestrictionMaintenanceControllerFixture(Db);

                var saveDetails = new NameRestrictionsSaveDetails
                {
                    Description = "123456789012345678901234567890123456789012345678901",
                    Action = KnownDebtorRestrictions.NoRestriction
                };

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(result.Errors.Length, 1);
                Assert.Equal(result.Errors[0].Message, "The value must not be greater than 50 characters.");
                Assert.Equal(result.Errors[0].Field, "description");
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNameRestrictonStatusAlreadyExist()
            {
                var f = new NameRestrictionMaintenanceControllerFixture(Db);

                new DebtorStatus(1)
                {
                    Status = "No Restriction",
                    RestrictionType = KnownDebtorRestrictions.NoRestriction
                }.In(Db);

                var saveDetails = new NameRestrictionsSaveDetails
                {
                    Description = "No Restriction",
                    Action = KnownDebtorRestrictions.NoRestriction
                };

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(result.Errors.Length, 1);
                Assert.Equal(result.Errors[0].Message, "field.errors.notunique");
                Assert.Equal(result.Errors[0].Field, "description");
            }

            [Fact]
            public void ShouldReturnErrorWhenPasswordIsNotSetAndActionRequiresPassword()
            {
                var f = new NameRestrictionMaintenanceControllerFixture(Db);

                var saveDetails = new NameRestrictionsSaveDetails
                {
                    Id = 1,
                    Description = "Display Warning",
                    Action = KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation
                };

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(result.Errors.Length, 1);
                Assert.Equal(result.Errors[0].Message, "field.errors.required");
                Assert.Equal(result.Errors[0].Field, "password");
            }

            [Fact]
            public void ShouldThrowErrorIfNameRestrictionDetailsNotFound()
            {
                var f = new NameRestrictionMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Save(null));
                Assert.IsType<ArgumentNullException>(e);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ShouldReturnErrorResultWhenNameRestrctionStatusAlreadyExist()
            {
                var f = new NameRestrictionMaintenanceControllerFixture(Db);

                new DebtorStatus(1)
                {
                    Status = "No Restriction",
                    RestrictionType = KnownDebtorRestrictions.NoRestriction
                }.In(Db);

                new DebtorStatus(2)
                {
                    Status = "Display Warning ",
                    RestrictionType = KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation
                }.In(Db);

                var saveDetails = new NameRestrictionsSaveDetails
                {
                    Id = 2,
                    Description = "No Restriction",
                    Action = KnownDebtorRestrictions.NoRestriction
                };

                var result = f.Subject.Update((short) saveDetails.Id, saveDetails);
                Assert.Equal(result.Errors.Length, 1);
                Assert.Equal(result.Errors[0].Message, "field.errors.notunique");
                Assert.Equal(result.Errors[0].Field, "description");
            }

            [Fact]
            public void ShouldThrowErrorIfNameRestrictionDetailsNull()
            {
                var f = new NameRestrictionMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Update(Fixture.Short(), null));
                Assert.IsType<ArgumentNullException>(e);
            }

            [Fact]
            public void ShouldThrowErrorIfNameRestrictionToBeEditedNotFound()
            {
                var f = new NameRestrictionMaintenanceControllerFixture(Db);
                var saveDetails = new NameRestrictionsSaveDetails
                {
                    Id = 1,
                    Description = "Display Warning",
                    Action = KnownDebtorRestrictions.NoRestriction
                };
                var e = Record.Exception(() => f.Subject.Update(Fixture.Short(), saveDetails));
                Assert.IsType<HttpResponseException>(e);
            }

            [Fact]
            public void ShoulReturnSuccessWhenSaved()
            {
                var f = new NameRestrictionMaintenanceControllerFixture(Db);

                var nameRestriction = new DebtorStatus(1)
                {
                    Status = "Display Warning",
                    RestrictionType = KnownDebtorRestrictions.NoRestriction
                }.In(Db);

                var saveDetails = new NameRestrictionsSaveDetails
                {
                    Id = nameRestriction.Id,
                    Description = "Display Warning with Confirmation",
                    Action = KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation,
                    Password = "1234"
                };

                var result = f.Subject.Update((short) saveDetails.Id, saveDetails);

                var updated =
                    Db.Set<DebtorStatus>()
                      .First(nt => nt.Id == saveDetails.Id);

                Assert.Equal(nameRestriction.Id, result.UpdatedId);
                Assert.Equal(saveDetails.Description, updated.Status);
                Assert.Equal(saveDetails.Action, updated.RestrictionAction);
                Assert.Equal(saveDetails.Password, updated.ClearTextPassword);
                Assert.Equal("success", result.Result);
                Assert.Equal(nameRestriction.Id, result.UpdatedId);
            }
        }
    }
}