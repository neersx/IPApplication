using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.KeepOnTopNotes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration.KeepOnTopNotes;
using InprotechKaizen.Model.Security;
using NSubstitute;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.KeepOnTopNotes
{
    public class KeepOnTopTextTypesFacts
    {
        static dynamic SetupCaseTextType(InMemoryDbContext db)
        {
            var tt1 = new TextTypeBuilder().Build().In(db);
            var tt2 = new TextTypeBuilder().Build().In(db);

            var kot1 = new KeepOnTopTextType { TextTypeId = tt1.Id, TextType = tt1, CaseProgram = true, NameProgram = true, TimeProgram = true, IsRegistered = true, IsPending = true, Type = KnownKotTypes.Case, BackgroundColor = "#00FF00" }.In(db);
            var kot2 = new KeepOnTopTextType { TextTypeId = tt2.Id, TextType = tt2, CaseProgram = true, TaskPlannerProgram = true, IsPending = true, Type = KnownKotTypes.Case }.In(db);

            var caseType1 = new CaseTypeBuilder().Build().In(db);
            var caseType2 = new CaseTypeBuilder().Build().In(db);

            var role1 = new Role(1) { RoleName = Fixture.String() }.In(db);
            var role2 = new Role(1) { RoleName = Fixture.String() }.In(db);

            var kotCt1 = new KeepOnTopCaseType { CaseType = caseType1, KotTextType = kot1 }.In(db);
            var kotCt2 = new KeepOnTopCaseType { CaseType = caseType2, KotTextType = kot1 }.In(db);
            var kotCt3 = new KeepOnTopCaseType { CaseType = caseType1, KotTextType = kot2 }.In(db);

            var kotR1 = new KeepOnTopRole { Role = role1, KotTextType = kot1 }.In(db);
            var kotR2 = new KeepOnTopRole { Role = role2, KotTextType = kot1 }.In(db);

            kot1.KotCaseTypes = new List<KeepOnTopCaseType> { kotCt1, kotCt2 };
            kot1.KotRoles = new List<KeepOnTopRole> { kotR1, kotR2 };
            kot2.KotCaseTypes = new List<KeepOnTopCaseType> { kotCt3 };

            return new
            {
                tt1,
                tt2,
                kot1,
                kot2,
                caseType1,
                caseType2,
                role1,
                role2
            };
        }

        static dynamic SetupNameTextType(InMemoryDbContext db)
        {
            var tt1 = new TextTypeBuilder().Build().In(db);

            var kot1 = new KeepOnTopTextType { TextTypeId = tt1.Id, TextType = tt1, CaseProgram = true, NameProgram = true, BillingProgram = true, Type = KnownKotTypes.Name, BackgroundColor = "#00FF00" }.In(db);

            var nameType1 = new NameTypeBuilder().Build().In(db);
            var nameType2 = new NameTypeBuilder().Build().In(db);

            var role1 = new Role(1) { RoleName = Fixture.String() }.In(db);
            var role2 = new Role(1) { RoleName = Fixture.String() }.In(db);

            var kotCt1 = new KeepOnTopNameType { NameType = nameType1, KotTextType = kot1 }.In(db);
            var kotCt2 = new KeepOnTopNameType { NameType = nameType2, KotTextType = kot1 }.In(db);

            var kotR1 = new KeepOnTopRole { Role = role1, KotTextType = kot1 }.In(db);
            var kotR2 = new KeepOnTopRole { Role = role2, KotTextType = kot1 }.In(db);

            kot1.KotNameTypes = new List<KeepOnTopNameType> { kotCt1, kotCt2 };
            kot1.KotRoles = new List<KeepOnTopRole> { kotR1, kotR2 };

            return new
            {
                kot1,
                nameType1,
                nameType2,
                role1,
                role2
            };
        }

        public class GetKotTextTypes : FactBase
        {
            [Fact]
            public void ReturnEmptyResultSetForCaseWhenNoData()
            {
                var f = new KeepOnTopTextTypesFixture(Db);
                var results = f.Subject.GetKotTextTypes(KnownKotTypes.Case).ToArray();
                Assert.Empty(results);
            }

            [Fact]
            public void ReturnsAllKotCaseTextTypes()
            {
                var f = new KeepOnTopTextTypesFixture(Db);
                var data = SetupCaseTextType(Db);
                var kot1 = (KeepOnTopTextType)data.kot1;

                var results = f.Subject.GetKotTextTypes(KnownKotTypes.Case).ToArray();

                Assert.Equal(2, results.Length);
                Assert.Equal(kot1.Id, results[0].Id);
                Assert.Equal(kot1.TextType.TextDescription, results[0].TextType);
                Assert.Equal($"{data.caseType1.Name}, {data.caseType2.Name}", results[0].CaseTypes);
                Assert.Equal($"{data.role1.RoleName}, {data.role2.RoleName}", results[0].Roles);
                Assert.Equal($"{KnownKotModules.Case}, {KnownKotModules.Name}, {KnownKotModules.Time}", results[0].Modules);
                Assert.Equal($"{KnownKotModules.Case}, {KnownKotModules.TaskPlanner}", results[1].Modules);
                Assert.Equal($"{KnownKotCaseStatus.Pending}, {KnownKotCaseStatus.Registered}", results[0].StatusSummary);
                Assert.Equal($"{KnownKotCaseStatus.Pending}", results[1].StatusSummary);
                Assert.Equal("#00FF00", results[0].BackgroundColor);
            }

            [Fact]
            public void ReturnsFilteredKotCaseTextTypes()
            {
                var f = new KeepOnTopTextTypesFixture(Db);
                var data = SetupCaseTextType(Db);
                var kot1 = (KeepOnTopTextType)data.kot1;
                var options = new KeepOnTopSearchOptions()
                {
                    Modules = "Billing,Time Recording".Split(','),
                    Statuses = "Registered".Split(','),
                    Type = KnownKotTypes.Case
                };

                var results = f.Subject.GetKotTextTypes(KnownKotTypes.Case, options).ToArray();

                Assert.Equal(1, results.Length);
                Assert.Equal(kot1.Id, results[0].Id);
                Assert.Equal(kot1.TextType.TextDescription, results[0].TextType);
                Assert.Equal($"{KnownKotModules.Case}, {KnownKotModules.Name}, {KnownKotModules.Time}", results[0].Modules);
            }

            [Fact]
            public void ReturnsAllKotNameTextTypes()
            {
                var f = new KeepOnTopTextTypesFixture(Db);
                var data = SetupNameTextType(Db);
                var kot1 = (KeepOnTopTextType)data.kot1;

                var results = f.Subject.GetKotTextTypes(KnownKotTypes.Name).ToArray();

                Assert.Equal(1, results.Length);
                Assert.Equal(kot1.Id, results[0].Id);
                Assert.Equal(kot1.TextType.TextDescription, results[0].TextType);
                Assert.Equal($"{data.nameType1.Name}, {data.nameType2.Name}", results[0].NameTypes);
                Assert.Equal($"{data.role1.RoleName}, {data.role2.RoleName}", results[0].Roles);
                Assert.Equal($"{KnownKotModules.Case}, {KnownKotModules.Name}, {KnownKotModules.Billing}", results[0].Modules);
                Assert.Null(results[0].StatusSummary);
                Assert.Equal("#00FF00", results[0].BackgroundColor);
            }

            [Fact]
            public void ReturnsFilteredKotNameTextTypes()
            {
                var f = new KeepOnTopTextTypesFixture(Db);
                var options = new KeepOnTopSearchOptions()
                {
                    Statuses = "Dead,Pending".Split(','),
                    Type = KnownKotTypes.Name
                };

                var results = f.Subject.GetKotTextTypes(KnownKotTypes.Name, options).ToArray();
                Assert.Equal(0, results.Length);
            }
        }

        public class GetKotTextTypeDetails : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionWhenIdDoesNotExist()
            {
                var f = new KeepOnTopTextTypesFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetKotTextTypeDetails(Fixture.Integer(), KnownKotTypes.Case));
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task GetCaseTextType()
            {
                var f = new KeepOnTopTextTypesFixture(Db);
                var data = SetupCaseTextType(Db);
                var kot1 = (KeepOnTopTextType)data.kot1;
                var result = await f.Subject.GetKotTextTypeDetails(kot1.Id, KnownKotTypes.Case);

                Assert.Equal(kot1.Id, result.Id);
                Assert.Equal(kot1.TextType.TextDescription, result.TextType.Value);
                Assert.Equal(2, result.CaseTypes.Count());
                Assert.Equal(data.caseType1.Name, result.CaseTypes.First().Value);
                Assert.Equal(2, result.Roles.Count());
                Assert.Equal(data.role1.RoleName, result.Roles.First().Value);
                Assert.True(result.HasCaseProgram);
                Assert.True(result.HasNameProgram);
                Assert.False(result.HasBillingProgram);
                Assert.True(result.HasTimeProgram);
                Assert.False(result.HasTaskPlannerProgram);
                Assert.True(result.IsPending);
                Assert.False(result.IsDead);
                Assert.True(result.IsRegistered);
                Assert.Equal("#00FF00", result.BackgroundColor);
            }

            [Fact]
            public async Task GetNameTextType()
            {
                var f = new KeepOnTopTextTypesFixture(Db);
                var data = SetupNameTextType(Db);
                var kot1 = (KeepOnTopTextType)data.kot1;
                var result = await f.Subject.GetKotTextTypeDetails(kot1.Id, KnownKotTypes.Name);

                Assert.Equal(kot1.Id, result.Id);
                Assert.Equal(kot1.TextType.TextDescription, result.TextType.Value);
                Assert.Equal(2, result.NameTypes.Count());
                Assert.Equal(data.nameType1.Name, result.NameTypes.First().Value);
                Assert.Equal(2, result.Roles.Count());
                Assert.Equal(data.role1.RoleName, result.Roles.First().Value);
                Assert.True(result.HasCaseProgram);
                Assert.True(result.HasNameProgram);
                Assert.True(result.HasBillingProgram);
                Assert.False(result.HasTimeProgram);
                Assert.False(result.HasTaskPlannerProgram);
                Assert.False(result.IsPending);
                Assert.False(result.IsDead);
                Assert.False(result.IsRegistered);
                Assert.Equal("#00FF00", result.BackgroundColor);
            }
        }

        public class SaveKotTextType : FactBase
        {
            [Fact]
            public async Task ShouldAddCaseKotData()
            {
                var tt = new TextTypeBuilder().Build().In(Db);
                var caseType1 = new CaseTypeBuilder().Build().In(Db);
                var caseType2 = new CaseTypeBuilder().Build().In(Db);
                var role1 = new Role(1) { RoleName = Fixture.String() }.In(Db);
                var role2 = new Role(1) { RoleName = Fixture.String() }.In(Db);
                var kotData = new KotTextTypeData
                {
                    TextType = new TextType(tt.Id, tt.TextDescription),
                    CaseTypes = new List<CaseType>
                    {
                        new CaseType {Key = caseType1.Id, Code = caseType1.Code, Value = caseType1.Name},
                        new CaseType {Key = caseType2.Id, Code = caseType2.Code, Value = caseType2.Name}
                    },
                    Roles = new List<RolesPicklistController.RolesPicklistItem>
                    {
                        new RolesPicklistController.RolesPicklistItem {Key = role1.Id, Value = role1.RoleName},
                        new RolesPicklistController.RolesPicklistItem {Key = role2.Id, Value = role2.RoleName}
                    },
                    BackgroundColor = "#00FF00",
                    IsRegistered = true,
                    HasTimeProgram = true
                };

                var f = new KeepOnTopTextTypesFixture(Db);
                var result = await f.Subject.SaveKotTextType(kotData, KnownKotTypes.Case);
                Assert.NotNull(result);
                var newKotTextType = Db.Set<KeepOnTopTextType>().First();
                var kotCaseTypes = Db.Set<KeepOnTopCaseType>().Where(_ => _.KotTextTypeId == newKotTextType.Id);
                var kotRoles = Db.Set<KeepOnTopRole>().Where(_ => _.KotTextTypeId == newKotTextType.Id);
                Assert.Equal(newKotTextType.Id, result.Id);
                Assert.Equal(kotData.BackgroundColor, newKotTextType.BackgroundColor);
                Assert.Equal(kotData.TextType.Key, newKotTextType.TextTypeId);
                Assert.Equal(kotData.CaseTypes.Count(), kotCaseTypes.Count());
                Assert.Equal(kotData.CaseTypes.First().Code, kotCaseTypes.First().CaseTypeId);
                Assert.Equal(kotData.Roles.Count(), kotRoles.Count());
                Assert.Equal(kotData.Roles.First().Key, kotRoles.First().RoleId);
                Assert.Equal(KnownKotTypes.Case, newKotTextType.Type);
                Assert.True(newKotTextType.IsRegistered);
                Assert.False(newKotTextType.IsPending);
                Assert.False(newKotTextType.IsDead);
                Assert.True(newKotTextType.TimeProgram);
                Assert.False(newKotTextType.CaseProgram);
                Assert.False(newKotTextType.BillingProgram);
            }

            [Fact]
            public async Task ShouldAddNameKotData()
            {
                var tt = new TextTypeBuilder().Build().In(Db);
                var nt = new NameTypeBuilder().Build().In(Db);
                var role1 = new Role(1) { RoleName = Fixture.String() }.In(Db);
                var role2 = new Role(1) { RoleName = Fixture.String() }.In(Db);
                var kotData = new KotTextTypeData
                {
                    TextType = new TextType(tt.Id, tt.TextDescription),
                    NameTypes = new List<NameTypeModel>
                    {
                        new NameTypeModel {Key = nt.Id, Code = nt.NameTypeCode, Value = nt.Name}
                    },
                    Roles = new List<RolesPicklistController.RolesPicklistItem>
                    {
                        new RolesPicklistController.RolesPicklistItem {Key = role1.Id, Value = role1.RoleName},
                        new RolesPicklistController.RolesPicklistItem {Key = role2.Id, Value = role2.RoleName}
                    },
                    BackgroundColor = "#00FF00",
                    HasTimeProgram = true,
                    HasCaseProgram = true
                };

                var f = new KeepOnTopTextTypesFixture(Db);
                var result = await f.Subject.SaveKotTextType(kotData, KnownKotTypes.Name);
                Assert.NotNull(result);
                var newKotTextType = Db.Set<KeepOnTopTextType>().First();
                var kotNameTypes = Db.Set<KeepOnTopNameType>().Where(_ => _.KotTextTypeId == newKotTextType.Id);
                var kotRoles = Db.Set<KeepOnTopRole>().Where(_ => _.KotTextTypeId == newKotTextType.Id);
                Assert.Equal(newKotTextType.Id, result.Id);
                Assert.Equal(kotData.BackgroundColor, newKotTextType.BackgroundColor);
                Assert.Equal(kotData.TextType.Key, newKotTextType.TextTypeId);
                Assert.Equal(1, kotNameTypes.Count());
                Assert.Equal(kotData.NameTypes.First().Code, kotNameTypes.First().NameTypeId);
                Assert.Equal(kotData.Roles.Count(), kotRoles.Count());
                Assert.Equal(kotData.Roles.First().Key, kotRoles.First().RoleId);
                Assert.Equal(KnownKotTypes.Name, newKotTextType.Type);
                Assert.True(newKotTextType.TimeProgram);
                Assert.True(newKotTextType.CaseProgram);
                Assert.False(newKotTextType.NameProgram);
                Assert.False(newKotTextType.TaskPlannerProgram);
                Assert.False(newKotTextType.IsRegistered);
                Assert.False(newKotTextType.IsPending);
                Assert.False(newKotTextType.IsDead);
            }

            [Fact]
            public async Task ShouldReturnNullException()
            {
                var f = new KeepOnTopTextTypesFixture(Db);
                await Assert.ThrowsAsync<ArgumentNullException>(async () => { await f.Subject.SaveKotTextType(null, KnownKotTypes.Name); });

            }

            [Fact]
            public async Task ShouldUpdateCaseKotData()
            {
                var data = SetupCaseTextType(Db);
                var kot = (KeepOnTopTextType)data.kot1;
                var caseType1 = (InprotechKaizen.Model.Cases.CaseType)data.caseType1;
                var role1 = new Role(1) { RoleName = Fixture.String() }.In(Db);
                var role2 = new Role(1) { RoleName = Fixture.String() }.In(Db);
                var kotData = new KotTextTypeData
                {
                    Id = kot.Id,
                    TextType = new TextType(kot.TextTypeId, kot.TextType.TextDescription),
                    CaseTypes = new List<CaseType>
                    {
                        new CaseType {Key = caseType1.Id, Code = caseType1.Code, Value = caseType1.Name}
                    },
                    Roles = new List<RolesPicklistController.RolesPicklistItem>
                    {
                        new RolesPicklistController.RolesPicklistItem {Key = role1.Id, Value = role1.RoleName},
                        new RolesPicklistController.RolesPicklistItem {Key = role2.Id, Value = role2.RoleName}
                    },
                    BackgroundColor = "#00FF00",
                    IsRegistered = true,
                    HasTimeProgram = true
                };

                var f = new KeepOnTopTextTypesFixture(Db);
                var result = await f.Subject.SaveKotTextType(kotData, KnownKotTypes.Case);
                Assert.NotNull(result);
                var newKotTextType = Db.Set<KeepOnTopTextType>().First(_ => _.Id == kot.Id);
                var kotCaseTypes = Db.Set<KeepOnTopCaseType>().Where(_ => _.KotTextTypeId == newKotTextType.Id);
                var kotRoles = Db.Set<KeepOnTopRole>().Where(_ => _.KotTextTypeId == newKotTextType.Id);
                Assert.Equal(newKotTextType.Id, result.Id);
                Assert.Equal(kotData.BackgroundColor, newKotTextType.BackgroundColor);
                Assert.Equal(kotData.TextType.Key, newKotTextType.TextTypeId);
                Assert.Equal(kotData.CaseTypes.Count(), kotCaseTypes.Count());
                Assert.Equal(kotData.CaseTypes.First().Code, kotCaseTypes.First().CaseTypeId);
                Assert.Equal(kotData.Roles.Count(), kotRoles.Count());
                Assert.Equal(kotData.Roles.First().Key, kotRoles.First().RoleId);
                Assert.True(newKotTextType.TimeProgram);
                Assert.False(newKotTextType.CaseProgram);
                Assert.False(newKotTextType.NameProgram);
                Assert.False(newKotTextType.TaskPlannerProgram);
                Assert.True(newKotTextType.IsRegistered);
                Assert.False(newKotTextType.IsPending);
                Assert.False(newKotTextType.IsDead);
            }

            [Fact]
            public async Task ShouldThrowsErrorWhenDuplicateCaseKotTextType()
            {
                var f = new KeepOnTopTextTypesFixture(Db);
                var data = SetupCaseTextType(Db);
                var tt = (InprotechKaizen.Model.Cases.TextType)data.tt1;
                var kotData = new KotTextTypeData
                {
                    TextType = new TextType { Key = tt.Id, Value = tt.TextDescription },
                    IsRegistered = true,
                    HasTimeProgram = true
                };
                var response = await f.Subject.SaveKotTextType(kotData, KnownKotTypes.Case);
                Assert.Equal("field.errors.duplicateTextType", response.Error.Message);
                Assert.Null(response.Id);
            }
        }

        public class DeleteKotTextType : FactBase
        {
            [Fact]
            public async Task ShouldDeleteKot()
            {
                var data = SetupCaseTextType(Db);
                var kot = (KeepOnTopTextType)data.kot1;
                var f = new KeepOnTopTextTypesFixture(Db);
                var response = await f.Subject.DeleteKotTextType(kot.Id);
                Assert.Equal("success", response.Result);
                Assert.Null(Db.Set<KeepOnTopTextType>().FirstOrDefault(_ => _.Id == kot.Id));
            }

            [Fact]
            public async Task ShouldThrowErrorWhenIdNotExist()
            {
                var f = new KeepOnTopTextTypesFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () =>
                {
                    await f.Subject.DeleteKotTextType(Fixture.Integer());
                });
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }
        }
    }

    public class KeepOnTopTextTypesFixture : IFixture<KeepOnTopTextTypes>
    {
        public KeepOnTopTextTypesFixture(InMemoryDbContext db)
        {
            CultureResolver = Substitute.For<IPreferredCultureResolver>();
            Translator = Substitute.For<IStaticTranslator>();

            Subject = new KeepOnTopTextTypes(db, CultureResolver, Translator);

            Translator.TranslateWithDefault("kotTextTypes.maintenance.pending", Arg.Any<IEnumerable<string>>()).Returns(KnownKotCaseStatus.Pending);
            Translator.TranslateWithDefault("kotTextTypes.maintenance.registered", Arg.Any<IEnumerable<string>>()).Returns(KnownKotCaseStatus.Registered);
            Translator.TranslateWithDefault("kotTextTypes.maintenance.dead", Arg.Any<IEnumerable<string>>()).Returns(KnownKotCaseStatus.Dead);
            Translator.TranslateWithDefault("kotTextTypes.maintenance.caseProgram", Arg.Any<IEnumerable<string>>()).Returns(KnownKotModules.Case);
            Translator.TranslateWithDefault("kotTextTypes.maintenance.nameProgram", Arg.Any<IEnumerable<string>>()).Returns(KnownKotModules.Name);
            Translator.TranslateWithDefault("kotTextTypes.maintenance.timeProgram", Arg.Any<IEnumerable<string>>()).Returns(KnownKotModules.Time);
            Translator.TranslateWithDefault("kotTextTypes.maintenance.billingProgram", Arg.Any<IEnumerable<string>>()).Returns(KnownKotModules.Billing);
            Translator.TranslateWithDefault("kotTextTypes.maintenance.taskPlannerProgram", Arg.Any<IEnumerable<string>>()).Returns(KnownKotModules.TaskPlanner);
        }

        public IStaticTranslator Translator { get; set; }
        public IPreferredCultureResolver CultureResolver { get; set; }
        public KeepOnTopTextTypes Subject { get; set; }
    }
}