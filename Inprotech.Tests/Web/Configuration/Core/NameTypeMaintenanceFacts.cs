using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;
using ValidationError = Inprotech.Infrastructure.Validations.ValidationError;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class NameTypeMaintenanceControllerFacts : FactBase
    {
        public class NameTypeMaintenanceControllerFixture : IFixture<NameTypeMaintenanceController>
        {
            public NameTypeMaintenanceControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                Validator = Substitute.For<INameTypeValidator>();
                Subject = new NameTypeMaintenanceController(DbContext, Validator);
            }

            public InMemoryDbContext DbContext { get; }
            public INameTypeValidator Validator { get; set; }
            public NameTypeMaintenanceController Subject { get; }

            public NameTypeMaintenanceControllerFixture WithValidation()
            {
                Validator.Validate(Arg.Any<NameTypeSaveDetails>(), Arg.Any<Operation>()).Returns(Enumerable.Empty<ValidationError>());
                return this;
            }

            public NameTypeMaintenanceControllerFixture WithUniqueValidationError(string forField)
            {
                Validator.Validate(Arg.Any<NameTypeSaveDetails>(), Arg.Any<Operation>()).Returns(new[] {ValidationErrors.NotUnique(forField)});
                return this;
            }

            public NameTypeSaveDetails GetNameTypeSaveDetails()
            {
                var nameRelation = new NameRelation("SB", "Send Bills To", Fixture.String(), 0, false, 0).In(DbContext);

                var nameTypeGroup1 = new NameTypeGroup {Key = 501, Value = "AAA"};
                var nameTypeGroup2 = new NameTypeGroup {Key = 502, Value = "BBB"};
                var nameTypeGroup3 = new NameTypeGroup {Key = 503, Value = "CCC"};

                return new NameTypeSaveDetails
                {
                    Id = 1,
                    NameTypeCode = "TQ",
                    Name = Fixture.String(),
                    MaximumAllowed = 10,
                    IsMandatory = false,
                    AllowStaffNames = false,
                    AllowClientNames = true,
                    AllowIndividualNames = true,
                    AllowOrganisationNames = true,
                    AllowCrmNames = true,
                    AllowSuppliers = true,
                    IsAddressDisplayed = true,
                    IsAssignDateDisplayed = true,
                    IsClassified = true,
                    IsCorrespondenceDisplayed = true,
                    IsNameStreetSaved = true,
                    IsStandardNameDisplayed = true,
                    DisplayNameCode = DisplayNameCode.Start,
                    EthicalWallOption = EthicalWallOption.AllowAccess,
                    PathNameTypePickList = new NameTypeModel
                    {
                        Key = 1,
                        Code = "A",
                        Value = "Agent"
                    },
                    PathNameRelation = new NameRelationshipModel(nameRelation.RelationshipCode, nameRelation.RelationDescription, nameRelation.ReverseDescription, string.Empty),
                    UpdateFromParentNameType = true,
                    UseNameType = true,
                    UseHomeNameRelationship = false,
                    ChangeEvent = new Event
                    {
                        Key = 1,
                        Code = "OPP",
                        Value = "Opposition"
                    },
                    OldNameTypePickList = new NameTypeModel
                    {
                        Key = 2,
                        Code = "AO",
                        Value = "Agent Old"
                    },
                    FutureNameTypePickList = new NameTypeModel
                    {
                        Key = 3,
                        Code = "AN",
                        Value = "Agent New"
                    },
                    NameTypeGroup = new List<NameTypeGroup> {nameTypeGroup1, nameTypeGroup2, nameTypeGroup3},
                    IsNationalityDisplayed = true
                };
            }
        }

        public class SearchMethod : FactBase
        {
            public List<NameType> PrepareData()
            {
                var nameType1 = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Debtor, Name = "Instructor", PriorityOrder = 0}.Build().In(Db);
                var nameType2 = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Contact, Name = "Contact", PriorityOrder = 2}.Build().In(Db);
                var nameType3 = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Owner, Name = "Owner", PriorityOrder = 1}.Build().In(Db);
                var nametypelist = new List<NameType> {nameType1, nameType2, nameType3};

                var nameGroup1 = new NameGroup(501, "AAA").In(Db);
                var nameGroup2 = new NameGroup(502, "BBB").In(Db);
                var nameGroup3 = new NameGroup(503, "CCC").In(Db);
                var nameGroup4 = new NameGroup(504, "DDD").In(Db);

                new NameGroupMember(nameGroup1, nameType1).In(Db);
                new NameGroupMember(nameGroup2, nameType2).In(Db);
                new NameGroupMember(nameGroup3, nameType2).In(Db);
                new NameGroupMember(nameGroup4, nameType3).In(Db);

                return nametypelist;
            }

            [Fact]
            public void ShouldReturnListOfMatchingNameTypesWhenSearchOptionIsProvided()
            {
                var nameTypeList = PrepareData();
                var searchOptions = new NameTypeSearchOptions
                {
                    Text = "Ins"
                };
                var f = new NameTypeMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(searchOptions);
                dynamic nametype = e.SingleOrDefault();
                Assert.NotNull(e);
                Assert.NotNull(nametype);
                Assert.Equal(nametype.Description, nameTypeList[0].Name);
            }

            [Fact]
            public void ShouldReturnListOfMatchingRecordsBasedOnNameTypeGroups()
            {
                var nameTypeList = PrepareData();
                var nameTypeGroup1 = new NameTypeGroup
                {
                    Key = 501,
                    Value = "AAA"
                };

                var nameTypeGroup2 = new NameTypeGroup
                {
                    Key = 502,
                    Value = "BBB"
                };

                ICollection<NameTypeGroup> nameTypeGroups = new List<NameTypeGroup>();
                nameTypeGroups.Add(nameTypeGroup1);
                nameTypeGroups.Add(nameTypeGroup2);

                var searchOptions = new NameTypeSearchOptions
                {
                    Text = string.Empty,
                    NameTypeGroup = nameTypeGroups
                };
                var f = new NameTypeMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(searchOptions);
                dynamic nametype = e.ToList();
                Assert.NotNull(e);
                Assert.NotNull(nametype);
                Assert.Equal(nametype.Count, 2);
                Assert.Equal(nametype[0].Description, nameTypeList[0].Name);
            }

            [Fact]
            public void ShouldReturnListOfMatchingRecordsBasedOnNameTypesAndNameTypeGroups()
            {
                var nameTypeList = PrepareData();
                var nameTypeGroup1 = new NameTypeGroup
                {
                    Key = 501,
                    Value = "AAA"
                };

                var nameTypeGroup2 = new NameTypeGroup
                {
                    Key = 502,
                    Value = "BBB"
                };

                ICollection<NameTypeGroup> nameTypeGroups = new List<NameTypeGroup>();
                nameTypeGroups.Add(nameTypeGroup1);
                nameTypeGroups.Add(nameTypeGroup2);

                var searchOptions = new NameTypeSearchOptions
                {
                    Text = "Ins",
                    NameTypeGroup = nameTypeGroups
                };
                var f = new NameTypeMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(searchOptions);
                dynamic nametype = e.SingleOrDefault();
                Assert.NotNull(e);
                Assert.NotNull(nametype);
                Assert.Equal(nametype.Description, nameTypeList[0].Name);
                Assert.Equal(((IEnumerable<NameTypeGroupMember>) nametype.NameTypeGroups).First().Id, nameTypeGroup1.Key);
            }

            [Fact]
            public void ShouldReturnListOfNameTypesInPriorityOrder()
            {
                var nameTypeList = PrepareData();
                var f = new NameTypeMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(null);
                Assert.NotNull(e);
                dynamic result = e as IList<object> ?? e.ToList();
                Assert.Equal(result.Count, nameTypeList.Count);
                Assert.Equal(result[0].Code, nameTypeList[0].NameTypeCode);
                Assert.Equal(result[1].Code, nameTypeList[2].NameTypeCode);
            }

            [Fact]
            public void ShouldReturnListOfNameTypesWhenSearchOptionIsNotProvided()
            {
                var nameTypeList = PrepareData();
                var f = new NameTypeMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(null);
                Assert.NotNull(e);
                Assert.Equal(e.Count(), nameTypeList.Count);
            }
        }

        public class GetNameTypeMethod : FactBase
        {
            [Fact]
            public void ShouldReturnNameTypeDetails()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                var nameType = new NameType(1, "E", "Test").In(Db);

                var r = f.Subject.GetNameType(1);
                Assert.Equal(nameType.Id, r.Id);
                Assert.Equal(nameType.NameTypeCode, r.NameTypeCode);
                Assert.Equal(nameType.Name, r.Name);
            }

            [Fact]
            public void ShouldThrowErrorIfNameTypeNotFound()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.GetNameType(1));
                Assert.IsType<HttpResponseException>(e);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ShouldCreateNewNameTypeWithGivenDetails()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                f.WithValidation();

                new NameGroup(501, "AAA").In(Db);
                new NameGroup(502, "BBB").In(Db);
                new NameGroup(503, "CCC").In(Db);

                var saveDetails = f.GetNameTypeSaveDetails();
                f.Subject.Save(saveDetails);

                var nameType =
                    Db.Set<NameType>().FirstOrDefault(nt => nt.NameTypeCode == saveDetails.NameTypeCode);

                var nameGroupMember =
                    Db.Set<NameGroupMember>().ToList();

                Assert.NotNull(nameType);
                Assert.Equal(saveDetails.Name, nameType.Name);
                Assert.Equal(saveDetails.MaximumAllowed, nameType.MaximumAllowed);
                Assert.Equal(0m, nameType.MandatoryFlag);
                Assert.Equal(saveDetails.AllowStaffNames, nameType.AllowStaffNames);
                Assert.Equal(saveDetails.AllowClientNames, nameType.AllowClientNames);
                Assert.Equal(saveDetails.AllowIndividualNames, nameType.AllowIndividualNames);
                Assert.Equal(saveDetails.AllowOrganisationNames, nameType.AllowOrganisationNames);
                Assert.Equal(saveDetails.AllowCrmNames, nameType.AllowCrmNames);
                Assert.Equal(saveDetails.AllowSuppliers, nameType.AllowSuppliers);
                Assert.Equal(saveDetails.IsAddressDisplayed, nameType.IsAddressDisplayed);
                Assert.Equal(saveDetails.IsAssignDateDisplayed, nameType.IsAssignDateDisplayed);
                Assert.Equal(saveDetails.IsClassified, nameType.IsClassified);
                Assert.Equal(saveDetails.IsCorrespondenceDisplayed, nameType.IsCorrespondenceDisplayed);
                Assert.Equal(saveDetails.IsNameStreetSaved, nameType.IsNameStreetSaved);
                Assert.Equal(saveDetails.IsStandardNameDisplayed, nameType.IsStandardNameDisplayed);
                Assert.Equal(Convert.ToDecimal(saveDetails.DisplayNameCode), nameType.ShowNameCode);
                if (nameType.PickListFlags != null) Assert.Equal(125, nameType.PickListFlags.Value);
                if (nameType.ColumnFlag != null) Assert.Equal(2314, nameType.ColumnFlag.Value);
                Assert.Equal(saveDetails.PathNameTypePickList.Code, nameType.PathNameType);
                Assert.Equal(saveDetails.PathNameRelation.Key, nameType.PathRelationship);
                Assert.Equal(saveDetails.FutureNameTypePickList.Code, nameType.FutureNameType);
                Assert.Equal(saveDetails.OldNameTypePickList.Code, nameType.OldNameType);
                Assert.Equal(saveDetails.UpdateFromParentNameType, nameType.UpdateFromParentNameType);
                Assert.Equal(saveDetails.UseNameType, nameType.UseNameType);
                Assert.Equal(saveDetails.UseHomeNameRelationship, nameType.UseHomeNameRelationship);
                Assert.Equal(saveDetails.ChangeEvent.Key, nameType.ChangeEventNo);
                Assert.Equal(saveDetails.EthicalWallOption, (EthicalWallOption) nameType.EthicalWall);
                Assert.Equal(saveDetails.IsNationalityDisplayed, nameType.NationalityFlag);
                Assert.Equal(nameGroupMember.Count, saveDetails.NameTypeGroup.Count);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenNameTypeCodeAlreadyExist()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                f.WithUniqueValidationError("nameTypeCode");
                var saveDetails = f.GetNameTypeSaveDetails();
                var result = f.Subject.Save(saveDetails);
                Assert.NotNull(result.Errors);
                Assert.Single((IEnumerable<ValidationError>) result.Errors);
                Assert.Equal("nameTypeCode", ((IEnumerable<ValidationError>) result.Errors).First().Field);
                Assert.Equal("field.errors.notunique", ((IEnumerable<ValidationError>) result.Errors).First().Message);
            }

            [Fact]
            public void ShouldThrowErrorIfNameTypeDetailsNotFound()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Save(null));
                Assert.IsType<ArgumentNullException>(e);
            }

            [Fact]
            public void ShoulReturnSuccessWhenSaved()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                f.WithValidation();
                var saveDetails = f.GetNameTypeSaveDetails();
                saveDetails.NameTypeGroup = null;
                var result = f.Subject.Save(saveDetails);
                var nameType =
                    Db.Set<NameType>()
                      .FirstOrDefault(nt => nt.NameTypeCode == saveDetails.NameTypeCode);

                Assert.NotNull(nameType);
                Assert.Equal("success", result.Result);
                Assert.Equal(nameType.Id, result.UpdatedId);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ShouldDeleteNameGroupNameTypeMappingWhenNoNameGroupGiven()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                var nameTypeToBeUpdated = new NameType(1, "TQ", "TQ").In(Db);

                var nameGroup = new NameGroup(501, "AAA").In(Db);

                new NameGroupMember(nameGroup, nameTypeToBeUpdated).In(Db);

                f.WithValidation();

                var saveDetails = f.GetNameTypeSaveDetails();
                saveDetails.NameTypeGroup = null;
                f.Subject.Update((short) saveDetails.Id, saveDetails);

                var nameType =
                    Db.Set<NameType>().FirstOrDefault(nt => nt.NameTypeCode == saveDetails.NameTypeCode);

                var nameGroupMember =
                    Db.Set<NameGroupMember>().ToList();

                Assert.NotNull(nameType);
                Assert.Equal(saveDetails.Name, nameType.Name);
                Assert.Empty(nameGroupMember);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenChangedNameTypeCodeAlreadyExist()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                new NameType(1, "TQ", "TQ").In(Db);

                f.WithUniqueValidationError("nameTypeCode");

                var saveDetails = f.GetNameTypeSaveDetails();
                var result = f.Subject.Update((short) saveDetails.Id, saveDetails);
                Assert.NotNull(result.Errors);
                Assert.Single((IEnumerable<ValidationError>) result.Errors);
                Assert.Equal("nameTypeCode", ((IEnumerable<ValidationError>) result.Errors).First().Field);
                Assert.Equal("field.errors.notunique", ((IEnumerable<ValidationError>) result.Errors).First().Message);
            }

            [Fact]
            public void ShouldThrowErrorIfNameTypeDetailsNotFound()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Save(null));
                Assert.IsType<ArgumentNullException>(e);
            }

            [Fact]
            public void ShouldThrowErrorIfNameTypeToBeEditedNotFound()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);
                var saveDetails = f.GetNameTypeSaveDetails();
                var e = Record.Exception(() => f.Subject.Update((short) saveDetails.Id, saveDetails));
                Assert.IsType<HttpResponseException>(e);
            }

            [Fact]
            public void ShouldUpdateNameGroupMembersWithGivenDetails()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                var nameTypeToBeUpdated = new NameType(1, "TQ", "TQ").In(Db);

                var nameGroup1 = new NameGroup(501, "AAA").In(Db);
                var nameGroup2 = new NameGroup(502, "BBB").In(Db);
                var nameGroup3 = new NameGroup(503, "CCC").In(Db);
                var nameGroup4 = new NameGroup(504, "DDD").In(Db);

                new NameGroupMember(nameGroup1, nameTypeToBeUpdated).In(Db);
                new NameGroupMember(nameGroup2, nameTypeToBeUpdated).In(Db);
                new NameGroupMember(nameGroup3, nameTypeToBeUpdated).In(Db);
                new NameGroupMember(nameGroup4, nameTypeToBeUpdated).In(Db);

                f.WithValidation();

                var saveDetails = f.GetNameTypeSaveDetails();
                f.Subject.Update((short) saveDetails.Id, saveDetails);

                var nameType =
                    Db.Set<NameType>().FirstOrDefault(nt => nt.NameTypeCode == saveDetails.NameTypeCode);

                var nameGroupMember =
                    Db.Set<NameGroupMember>().ToList();

                Assert.NotNull(nameType);
                Assert.Equal(saveDetails.Name, nameType.Name);
                Assert.Equal(nameGroupMember.Count, saveDetails.NameTypeGroup.Count);
                Assert.Null(nameGroupMember.Find(x => x.NameGroupId == 504));
            }

            [Fact]
            public void ShouldUpdateNameTypeWithGivenDetails()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                new NameType(1, "TQ", "TQ").In(Db);

                f.WithValidation();

                var saveDetails = f.GetNameTypeSaveDetails();
                saveDetails.NameTypeGroup = null;
                f.Subject.Update((short) saveDetails.Id, saveDetails);

                var nameType =
                    Db.Set<NameType>().FirstOrDefault(nt => nt.NameTypeCode == saveDetails.NameTypeCode);

                Assert.NotNull(nameType);
                Assert.Equal(saveDetails.Name, nameType.Name);
                Assert.Equal(saveDetails.MaximumAllowed, nameType.MaximumAllowed);
                Assert.Equal(0m, nameType.MandatoryFlag);
                Assert.Equal(saveDetails.AllowStaffNames, nameType.AllowStaffNames);
                Assert.Equal(saveDetails.AllowClientNames, nameType.AllowClientNames);
                Assert.Equal(saveDetails.AllowIndividualNames, nameType.AllowIndividualNames);
                Assert.Equal(saveDetails.AllowOrganisationNames, nameType.AllowOrganisationNames);
                Assert.Equal(saveDetails.AllowCrmNames, nameType.AllowCrmNames);
                Assert.Equal(saveDetails.IsAddressDisplayed, nameType.IsAddressDisplayed);
                Assert.Equal(saveDetails.IsAssignDateDisplayed, nameType.IsAssignDateDisplayed);
                Assert.Equal(saveDetails.IsClassified, nameType.IsClassified);
                Assert.Equal(saveDetails.IsCorrespondenceDisplayed, nameType.IsCorrespondenceDisplayed);
                Assert.Equal(saveDetails.IsNameStreetSaved, nameType.IsNameStreetSaved);
                Assert.Equal(saveDetails.IsStandardNameDisplayed, nameType.IsStandardNameDisplayed);
                Assert.Equal(Convert.ToDecimal(saveDetails.DisplayNameCode), nameType.ShowNameCode);
                if (nameType.PickListFlags != null) Assert.Equal(125, nameType.PickListFlags.Value);
                if (nameType.ColumnFlag != null) Assert.Equal(2314, nameType.ColumnFlag.Value);
                Assert.Equal(saveDetails.PathNameTypePickList.Code, nameType.PathNameType);
                Assert.Equal(saveDetails.PathNameRelation.Key, nameType.PathRelationship);
                Assert.Equal(saveDetails.FutureNameTypePickList.Code, nameType.FutureNameType);
                Assert.Equal(saveDetails.OldNameTypePickList.Code, nameType.OldNameType);
                Assert.Equal(saveDetails.UpdateFromParentNameType, nameType.UpdateFromParentNameType);
                Assert.Equal(saveDetails.UseNameType, nameType.UseNameType);
                Assert.Equal(saveDetails.UseHomeNameRelationship, nameType.UseHomeNameRelationship);
                Assert.Equal(saveDetails.ChangeEvent.Key, nameType.ChangeEventNo);
                Assert.Equal(saveDetails.EthicalWallOption, (EthicalWallOption) nameType.EthicalWall);
            }

            [Fact]
            public void ShoulReturnSuccessWhenSaved()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                new NameType(1, "TQ", "TQ").In(Db);

                f.WithValidation();
                var saveDetails = f.GetNameTypeSaveDetails();
                saveDetails.NameTypeGroup = null;
                var result = f.Subject.Update((short) saveDetails.Id, saveDetails);
                var nameType =
                    Db.Set<NameType>()
                      .FirstOrDefault(nt => nt.NameTypeCode == saveDetails.NameTypeCode);

                Assert.NotNull(nameType);
                Assert.Equal("success", result.Result);
                Assert.Equal(nameType.Id, result.UpdatedId);
            }
        }

        public class UpdateNameTypeSequenceMethod : FactBase
        {
            public dynamic PrepareData()
            {
                var nameType1 = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Debtor, Name = "Instructor", PriorityOrder = 0}.Build().In(Db);
                var nameType2 = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Contact, Name = "Contact", PriorityOrder = 1}.Build().In(Db);
                var nameType3 = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Owner, Name = "Owner", PriorityOrder = 2}.Build().In(Db);
                return new
                {
                    nameType1,
                    nameType2,
                    nameType3
                };
            }

            [Fact]
            public void ThrowsArgumentNullExceptionWhenSaveDetailsIsPassedAsNull()
            {
                var f = new NameTypeMaintenanceControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.UpdateNameTypesSequence(null));

                Assert.IsType<ArgumentNullException>(exception);
                Assert.Contains("saveDetails", exception.Message);
            }

            [Fact]
            public void UpdateNameTypeSequence()
            {
                var nameTypes = PrepareData();

                var f = new NameTypeMaintenanceControllerFixture(Db);
                var result = f.Subject.UpdateNameTypesSequence(new[]
                {
                    new PriorityOrderSaveDetails {Id = nameTypes.nameType1.Id, PriorityOrder = 2},
                    new PriorityOrderSaveDetails {Id = nameTypes.nameType2.Id, PriorityOrder = 1},
                    new PriorityOrderSaveDetails {Id = nameTypes.nameType3.Id, PriorityOrder = 0}
                });

                Assert.Equal("success", result.Result);

                var id = (int) nameTypes.nameType1.Id;
                var displaySequence = Db.Set<NameType>()
                                        .First(_ => _.Id == id).PriorityOrder;
                Assert.Equal(2, displaySequence);
            }
        }
    }
}