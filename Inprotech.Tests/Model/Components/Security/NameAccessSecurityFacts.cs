using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security
{
    public class NameAccessSecurityFacts
    {
        public class NameAccessSecurityFixture : IFixture<NameAccessSecurity>
        {
            public NameAccessSecurityFixture(InMemoryDbContext db)
            {
                SecurityContext = Substitute.For<ISecurityContext>();
                Subject = new NameAccessSecurity(SecurityContext, db);
            }

            public ISecurityContext SecurityContext { get; set; }
            public NameAccessSecurity Subject { get; }
        }

        public class CanViewMethod : FactBase
        {
            dynamic Setup()
            {
                var currentUser = UserBuilder.AsInternalUser(Db).Build();
                var requestedName = new NameBuilder(Db).Build().In(Db);
                var requestedNameType = new NameTypeBuilder().Build();
                var sydneyOffice = new OfficeBuilder {Name = Fixture.String("Sydney")}.Build().In(Db);
                var noidaOffice = new OfficeBuilder {Name = Fixture.String("Noida")}.Build().In(Db);
                var existingReadOnlyRowAccess = new RowAccessProfileBuilder {Name = "ReadOnly"}.Build().In(Db);

                return new
                {
                    currentUser,
                    existingReadOnlyRowAccess,
                    requestedName,
                    requestedNameType,
                    sydneyOffice,
                    noidaOffice
                };
            }

            [Fact]
            public void ReturnsFalseIfUserNameRowAccessHasCaseTypeAndPropertyType()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                var caseType = new CaseTypeBuilder().Build().In(Db);
                var propertyType = new PropertyTypeBuilder().Build().In(Db);

                data.existingReadOnlyRowAccess.Details.Add(
                                                           RowAccessDetailBuilder
                                                               .ForName()
                                                               .And(caseType)
                                                               .And(propertyType)
                                                               .And(AccessPermissionLevel.Select)
                                                               .WithName("ReadOnly")
                                                               .Build().In(Db));

                f.SecurityContext.User.RowAccessPermissions.Add(data.existingReadOnlyRowAccess);

                var result = f.Subject.CanView(data.requestedName);
                Assert.False(result);
            }

            [Fact]
            public void ReturnsFalseIfUserNameRowAccessRequiresNameTypeButNameDoesnotHaveAssociatedNameType()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                data.existingReadOnlyRowAccess.Details.Add(RowAccessDetailBuilder
                                                           .ForName()
                                                           .And(data.requestedNameType as NameType)
                                                           .And(AccessPermissionLevel.Select)
                                                           .WithName("ReadOnly")
                                                           .Build().In(Db));

                f.SecurityContext.User.RowAccessPermissions.Add(data.existingReadOnlyRowAccess);

                var result = f.Subject.CanView(data.requestedName);
                Assert.False(result);
            }

            [Fact]
            public void ReturnsFalseIfUserNameRowAccessRequiresOfficeButNameDoesnotHaveOfficeAttribute()
            {
                var data = Setup();
                data.existingReadOnlyRowAccess.Details.Add(RowAccessDetailBuilder
                                                           .ForName()
                                                           .And(data.sydneyOffice as Office)
                                                           .And(AccessPermissionLevel.Select)
                                                           .WithName("ReadOnly")
                                                           .Build().In(Db));

                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);
                f.SecurityContext.User.RowAccessPermissions.Add(data.existingReadOnlyRowAccess);

                var result = f.Subject.CanView(data.requestedName);
                Assert.False(result);
            }

            [Fact]
            public void ReturnsTrueIfUserNameRowAccessRequiresNameTypeAndNameHaveAssociatedNameType()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                new NameTypeClassificationBuilder(Db)
                {
                    IsAllowed = 1,
                    NameType = data.requestedNameType,
                    Name = data.requestedName
                }.Build().In(Db);

                data.existingReadOnlyRowAccess.Details.Add(RowAccessDetailBuilder
                                                           .ForName()
                                                           .And(data.requestedNameType as NameType)
                                                           .And(AccessPermissionLevel.Select)
                                                           .WithName("ReadOnly")
                                                           .Build().In(Db));

                f.SecurityContext.User.RowAccessPermissions.Add(data.existingReadOnlyRowAccess);

                var result = f.Subject.CanView(data.requestedName);
                Assert.True(result);
            }

            [Fact]
            public void ReturnsTrueIfUserNameRowAccessRequiresNameTypeWithUpdateAndNameHaveAssociatedNameType()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                new NameTypeClassificationBuilder(Db)
                {
                    IsAllowed = 1,
                    NameType = data.requestedNameType,
                    Name = data.requestedName
                }.Build().In(Db);

                data.existingReadOnlyRowAccess.Details.Add(RowAccessDetailBuilder
                                                           .ForName()
                                                           .And(data.requestedNameType as NameType)
                                                           .And(AccessPermissionLevel.Update)
                                                           .WithName("ReadOnly")
                                                           .Build().In(Db));

                f.SecurityContext.User.RowAccessPermissions.Add(data.existingReadOnlyRowAccess);

                var result = f.Subject.CanView(data.requestedName);
                Assert.True(result);
            }

            [Fact]
            public void ReturnsTrueIfUserNameRowAccessRequiresOfficeAndNameHaveOfficeAttribute()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                var office = data.sydneyOffice as Office;
                if (office != null)
                {
                    TableAttributesBuilder
                        .ForName(data.requestedName as InprotechKaizen.Model.Names.Name)
                        .WithAttribute(TableTypes.Office, office.Id)
                        .Build().In(Db);
                }

                data.existingReadOnlyRowAccess.Details.Add(RowAccessDetailBuilder
                                                           .ForName()
                                                           .And(data.sydneyOffice as Office)
                                                           .And(AccessPermissionLevel.Select)
                                                           .WithName("ReadOnly")
                                                           .Build().In(Db));

                f.SecurityContext.User.RowAccessPermissions.Add(data.existingReadOnlyRowAccess);

                var result = f.Subject.CanView(data.requestedName);
                Assert.True(result);
            }

            [Fact]
            public void ReturnsTrueUserRowAccessPermissionDoesnotExist()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                var result = f.Subject.CanView(data.requestedName);
                Assert.True(result);
            }
        }

        public class CanUpdateMethod : FactBase
        {
            dynamic Setup()
            {
                var currentUser = UserBuilder.AsInternalUser(Db).Build();
                var requestedName = new NameBuilder(Db).Build().In(Db);
                var requestedNameType = new NameTypeBuilder().Build();
                var sydneyOffice = new OfficeBuilder {Name = Fixture.String("Sydney")}.Build().In(Db);
                var noidaOffice = new OfficeBuilder {Name = Fixture.String("Noida")}.Build().In(Db);
                var existingUpdateRowAccess = new RowAccessProfileBuilder {Name = "Update"}.Build().In(Db);

                return new
                {
                    currentUser,
                    existingUpdateRowAccess,
                    requestedName,
                    requestedNameType,
                    sydneyOffice,
                    noidaOffice
                };
            }

            [Fact]
            public void ReturnsFalseIfUserNameRowAccessHasSelectButUpdateIsRequired()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                new NameTypeClassificationBuilder(Db)
                {
                    IsAllowed = 1,
                    NameType = data.requestedNameType,
                    Name = data.requestedName
                }.Build().In(Db);

                data.existingUpdateRowAccess.Details.Add(RowAccessDetailBuilder
                                                         .ForName()
                                                         .And(data.requestedNameType as NameType)
                                                         .And(AccessPermissionLevel.Select)
                                                         .WithName("Update")
                                                         .Build().In(Db));

                f.SecurityContext.User.RowAccessPermissions.Add(data.existingUpdateRowAccess);

                var result = f.Subject.CanUpdate(data.requestedName);
                Assert.False(result);
            }

            [Fact]
            public void ReturnsFalseWhenNameMatchesPermissionForNameTypeButRowAccessHasBothNameTypeAndOffice()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                var office = data.sydneyOffice as Office;
                if (office != null)
                {
                    TableAttributesBuilder
                        .ForName(data.requestedName as InprotechKaizen.Model.Names.Name)
                        .WithAttribute(TableTypes.Office, office.Id)
                        .Build().In(Db);
                }

                new NameTypeClassificationBuilder(Db)
                {
                    IsAllowed = 1,
                    NameType = data.requestedNameType,
                    Name = data.requestedName
                }.Build().In(Db);

                data.existingUpdateRowAccess.Details.Add(RowAccessDetailBuilder
                                                         .ForName()
                                                         .And(data.requestedNameType as NameType)
                                                         .And(AccessPermissionLevel.Update | AccessPermissionLevel.Select)
                                                         .WithName("Update")
                                                         .Build().In(Db));
                data.existingUpdateRowAccess.Details.Add(RowAccessDetailBuilder
                                                         .ForName()
                                                         .And(data.sydneyOffice as Office)
                                                         .And(AccessPermissionLevel.Select)
                                                         .WithName("Update")
                                                         .Build().In(Db));
                f.SecurityContext.User.RowAccessPermissions.Add(data.existingUpdateRowAccess);

                // Give preferece to office over NameType
                var result = f.Subject.CanUpdate(data.requestedName);
                Assert.False(result);
            }
        }

        public class CanInsertMethod : FactBase
        {
            dynamic Setup()
            {
                var currentUser = UserBuilder.AsInternalUser(Db).Build();
                var requestedNameType = new NameTypeBuilder().Build();
                var unRestrictedNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.UnrestrictedNameTypes}.Build();
                var existingInsertRowAccess = new RowAccessProfileBuilder {Name = "Insert"}.Build().In(Db);

                return new
                {
                    currentUser,
                    existingInsertRowAccess,
                    unRestrictedNameType,
                    requestedNameType
                };
            }

            [Fact]
            public void ReturnsFalseIfUserIsExternal()
            {
                var externalUser = UserBuilder.AsExternalUser(Db, null).Build();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => externalUser);
                var result = f.Subject.CanInsert();
                Assert.False(result);
            }

            [Fact]
            public void ReturnsFalseIfUserNameRowAccessHasCaseTypeAndPropertyType()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                var caseType = new CaseTypeBuilder().Build().In(Db);
                var propertyType = new PropertyTypeBuilder().Build().In(Db);

                data.existingInsertRowAccess.Details.Add(
                                                         RowAccessDetailBuilder
                                                             .ForName()
                                                             .And(caseType)
                                                             .And(propertyType)
                                                             .And(AccessPermissionLevel.Insert)
                                                             .WithName("Insert")
                                                             .Build().In(Db));

                f.SecurityContext.User.RowAccessPermissions.Add(data.existingInsertRowAccess);

                var result = f.Subject.CanInsert();
                Assert.False(result);
            }

            [Fact]
            public void ReturnsFalseIfUserNameRowAccessRequiresNameTypeOtherThanUnrestricted()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                data.existingInsertRowAccess.Details.Add(RowAccessDetailBuilder
                                                         .ForName()
                                                         .And(data.requestedNameType as NameType)
                                                         .And(AccessPermissionLevel.Insert)
                                                         .WithName("Insert")
                                                         .Build().In(Db));

                f.SecurityContext.User.RowAccessPermissions.Add(data.existingInsertRowAccess);

                var result = f.Subject.CanInsert();
                Assert.False(result);
            }

            [Fact]
            public void ReturnsTrueIfUserNameRowAccessDoesNotRequiresNameType()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                data.existingInsertRowAccess.Details.Add(RowAccessDetailBuilder
                                                         .ForName()
                                                         .And(AccessPermissionLevel.Insert)
                                                         .WithName("Insert")
                                                         .Build().In(Db));

                f.SecurityContext.User.RowAccessPermissions.Add(data.existingInsertRowAccess);

                var result = f.Subject.CanInsert();
                Assert.True(result);
            }

            [Fact]
            public void ReturnsTrueIfUserNameRowAccessRequiresUnrestrictedNameType()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                data.existingInsertRowAccess.Details.Add(RowAccessDetailBuilder
                                                         .ForName()
                                                         .And(data.unRestrictedNameType as NameType)
                                                         .And(AccessPermissionLevel.Insert)
                                                         .WithName("Insert")
                                                         .Build().In(Db));

                f.SecurityContext.User.RowAccessPermissions.Add(data.existingInsertRowAccess);

                var result = f.Subject.CanInsert();
                Assert.True(result);
            }

            [Fact]
            public void ReturnsTrueIfUserRowAccessPermissionDoesnotExist()
            {
                var data = Setup();
                var f = new NameAccessSecurityFixture(Db);
                f.SecurityContext.User.Returns(c => data.currentUser);

                var result = f.Subject.CanInsert();
                Assert.True(result);
            }
        }
    }
}