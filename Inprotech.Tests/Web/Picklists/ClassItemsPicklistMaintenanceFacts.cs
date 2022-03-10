using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class ClassItemsPicklistMaintenanceFacts : FactBase
    {
        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CannotDeleteItemIfUsedInCase()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var setupData = f.SetupData();

                new CaseClassItem(setupData.@case.Id, setupData.definedItemDefault01.Id).In(Db);

                var r = f.Subject.Delete(setupData.definedItemDefault01.Id, false);

                Assert.Equal("entity.cannotdelete", r.Errors[0].Message);
            }

            [Fact]
            public void ShowConfirmationIfItemHasAssociatedLanguageItems()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var setupData = f.SetupData();

                var r = f.Subject.Delete(setupData.definedItemDefault01.Id, false);

                Assert.Equal("confirmation", r.Result);
                Assert.Equal(ConfigurationResources.ClassItemDeleteValidation, r.Message);
            }

            [Fact]
            public void DeleteAssociatedItemsOnConfirmation()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var setupData = f.SetupData();

                var r = f.Subject.Delete(setupData.definedItemDefault01.Id, true);
                string itemNo = setupData.definedItemDefault01.ItemNo;

                Assert.Equal("success", r.Result);
                Assert.Equal(true, r.RerunSearch);
                Assert.False(Db.Set<InprotechKaizen.Model.Configuration.ClassItem>().Any(_ => _.ItemNo.Equals(itemNo)));
            }

        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ThrowsExceptionWhenItemNotFound()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                f.SetupData();

                var exception =
                    Record.Exception(() => f.Subject.Get(Fixture.Integer()));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException)exception).Response.StatusCode);
            }

            [Fact]
            public void GetItemDetails()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var setupData = f.SetupData();

                int itemid = setupData.definedItemDefault01.Id;
                var item = f.Subject.Get(itemid);
                
                Assert.Equal(setupData.definedItemDefault01.ItemNo, item.ItemNo);
                Assert.Equal(setupData.definedItemDefault01.ItemDescription, item.ItemDescription);
                Assert.True(item.IsDefaultItem);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void AddDefaultClassItem()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var data = f.SetupData();

                var item = new ClassItemSaveDetails
                {
                    ItemNo = "I101",
                    ItemDescription = "I101 item for class 01 subclass B",
                    Language = null,
                    Class = data.class01B.Class,
                    Country = data.class01B.CountryCode,
                    PropertyType = data.class01B.PropertyType,
                    SubClass = data.class01B.SubClass
                };

                var result = f.Subject.Save(item, Operation.Add);

                Assert.Equal("success", result.Result);
                Assert.True(result.RerunSearch);
                Assert.NotNull(Db.Set<InprotechKaizen.Model.Configuration.ClassItem>()
                                .SingleOrDefault(_ => _.ItemNo.Equals("I101") && _.Language == null));
            }

            [Fact]
            public void AddLanguageClassItem()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var data = f.SetupData();

                var defaultItem = new ClassItemSaveDetails
                {
                    ItemNo = "I101",
                    ItemDescription = "I101 item for class 01 subclass B",
                    Language = null,
                    Class = data.class01B.Class,
                    Country = data.class01B.CountryCode,
                    PropertyType = data.class01B.PropertyType,
                    SubClass = data.class01B.SubClass
                };

                var id = (int)f.Subject.Save(defaultItem, Operation.Add).Key;

                //reload class detail for new record as inmemorydbcontext doesnot lazy load navigation props after save
                var dbRecord = Db.Set<InprotechKaizen.Model.Configuration.ClassItem>().Single(_ => _.Id.Equals(id));
                dbRecord.Class = data.class01B;
                //Db.SaveChanges();

                // add language item for default item I101 with class 01 and subclass B
                var languageItem = new ClassItemSaveDetails
                {
                    ItemNo = "I101",
                    ItemDescription = "I101 item in french for class 01 subclass B",
                    Language = new TableCodePicklistController.TableCodePicklistItem
                    {
                        Key = data.frenchTableCode.Id,
                        Code = data.frenchTableCode.UserCode,
                        Value = data.frenchTableCode.Name
                    },
                    Class = data.class01B.Class,
                    Country = data.class01B.CountryCode,
                    PropertyType = data.class01B.PropertyType,
                    SubClass = data.class01B.SubClass
                };

                var result = f.Subject.Save(languageItem, Operation.Add);
                Assert.Equal("success", result.Result);
                Assert.True(result.RerunSearch);
                Assert.Equal(2, Db.Set<InprotechKaizen.Model.Configuration.ClassItem>()
                                 .Count(_ => _.ItemNo.Equals("I101")));
            }

            [Fact]
            public void AddUndefinedItemWithItemNoAutoGenerated()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var internalCode = -2;
                f.LastInternalCodeGenerator
                        .GenerateNegativeLastInternalCode("CLASSITEM").Returns(internalCode);

                var data = f.SetupData();

                var item = new ClassItemSaveDetails
                {
                    ItemDescription = "Undefined Item I101 for class 01",
                    Language = null,
                    Class = data.class01.Class,
                    Country = data.class01.CountryCode,
                    PropertyType = data.class01.PropertyType,
                    SubClass = data.class01.SubClass
                };

                var result = f.Subject.Save(item, Operation.Add);
                var id = (int)result.Key;

                Assert.Equal("success", result.Result);
                Assert.True(result.RerunSearch);
                Assert.Equal(internalCode.ToString() ,Db.Set<InprotechKaizen.Model.Configuration.ClassItem>()
                                 .Single(_ => _.Id.Equals(id) && _.Language == null).ItemNo);
            }

            [Fact]
            public void UpdateClassItem()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var data = f.SetupData();

                var existingItemToUpdate = data.definedItemGerman01;
                
                var chineseTableCode = new TableCodeBuilder
                {
                    Description = "Chinese",
                    TableCode = Fixture.Integer(),
                    TableType = (short)TableTypes.Language,
                    UserCode = null
                }.Build().In(Db);

                //update german language to chinese
                var item = new ClassItemSaveDetails
                {
                    ItemNo = existingItemToUpdate.ItemNo,
                    ItemDescription = "Item01 in Chinese for Class 01 SubClass B",
                    Language = new TableCodePicklistController.TableCodePicklistItem
                    {
                        Key = chineseTableCode.Id,
                        Code = chineseTableCode.UserCode,
                        Value = chineseTableCode.Name
                    },
                    Class = existingItemToUpdate.Class.Class,
                    Country = existingItemToUpdate.Class.CountryCode,
                    PropertyType = existingItemToUpdate.Class.PropertyType,
                    SubClass = existingItemToUpdate.Class.SubClass,
                    Id = existingItemToUpdate.Id
                };

                var result = f.Subject.Save(item, Operation.Update);

                int existingItemId = existingItemToUpdate.Id;
                Assert.Equal("success", result.Result);
                Assert.True(result.RerunSearch);
                Assert.Equal(chineseTableCode.Id, Db.Set<InprotechKaizen.Model.Configuration.ClassItem>()
                                 .Single(_ => _.Id.Equals(existingItemId)).LanguageCode);
            }
        }

        public class ValidationsOnSave : FactBase
        {
            [Fact]
            public void ItemNoRequiredWhenSubClassIsSelected()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var data = f.SetupData();

                var item = new ClassItemSaveDetails
                {
                    ItemNo = string.Empty,
                    ItemDescription = "I101 item for class 01 subclass B",
                    Language = null,
                    Class = data.class01B.Class,
                    Country = data.class01B.CountryCode,
                    PropertyType = data.class01B.PropertyType,
                    SubClass = data.class01B.SubClass
                };

                var result = f.Subject.Save(item, Operation.Add);

                Assert.True(((Inprotech.Infrastructure.Validations.ValidationError[])result.Errors).Any());
                Assert.Equal("itemNo", result.Errors[0].Field);
                Assert.Equal("field.errors.required", result.Errors[0].Message);
            }

            [Fact]
            public void ItemNoRequiredWhenLanguageIsSelected()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var data = f.SetupData();

                var item = new ClassItemSaveDetails
                {
                    ItemNo = string.Empty,
                    ItemDescription = "I101 item for class 01 subclass B",
                    Language = new TableCodePicklistController.TableCodePicklistItem()
                    {
                        Code = Fixture.String(),
                        Key = Fixture.Integer(),
                        Value = Fixture.String()
                    },
                    Class = data.class01B.Class,
                    Country = data.class01B.CountryCode,
                    PropertyType = data.class01B.PropertyType,
                    SubClass = string.Empty
                };

                var result = f.Subject.Save(item, Operation.Add);

                Assert.True(((Inprotech.Infrastructure.Validations.ValidationError[])result.Errors).Any());
                Assert.Equal("itemNo", result.Errors[0].Field);
                Assert.Equal("field.errors.required", result.Errors[0].Message);
            }

            [Fact]
            public void CannotAddLanguageItemIfDefaultDoesnotExists()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var data = f.SetupData();

                // add language item for default item I101 with class 01 and subclass B
                var languageItem = new ClassItemSaveDetails
                {
                    ItemNo = "I101",
                    ItemDescription = "I101 item in french for class 01 subclass B",
                    Language = new TableCodePicklistController.TableCodePicklistItem
                    {
                        Key = data.frenchTableCode.Id,
                        Code = data.frenchTableCode.UserCode,
                        Value = data.frenchTableCode.Name
                    },
                    Class = data.class01B.Class,
                    Country = data.class01B.CountryCode,
                    PropertyType = data.class01B.PropertyType,
                    SubClass = data.class01B.SubClass
                };

                var result = f.Subject.Save(languageItem, Operation.Add);

                Assert.True(((Inprotech.Infrastructure.Validations.ValidationError[])result.Errors).Any());
                Assert.Equal("field.errors.defaultItemRequired", result.Errors[0].Message);
            }

            [Fact]
            public void ValidateUniqueItemDescriptionForClass()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var data = f.SetupData();
               
                var item = new ClassItemSaveDetails
                {
                    ItemNo = "I101",
                    ItemDescription = "Item01 for Class 01 SubClass B",
                    Language = null,
                    Class = data.class01B.Class,
                    Country = data.class01B.CountryCode,
                    PropertyType = data.class01B.PropertyType,
                    SubClass = data.class01B.SubClass
                };

                var result = f.Subject.Save(item, Operation.Add);

                Assert.True(((Inprotech.Infrastructure.Validations.ValidationError[])result.Errors).Any());
                Assert.Equal("itemDescription", result.Errors[0].Field); 
                Assert.Equal("field.errors.notunique", result.Errors[0].Message);
            }

            [Fact]
            public void ValidateUniqueClassItemCombination()
            {
                var f = new ClassItemPicklistMaintenanceFixture(Db);
                var data = f.SetupData();

                var item = new ClassItemSaveDetails
                {
                    ItemNo = "Item01B",
                    ItemDescription = "Item01B for Class 01 SubClass B",
                    Language = null,
                    Class = data.class01B.Class,
                    Country = data.class01B.CountryCode,
                    PropertyType = data.class01B.PropertyType,
                    SubClass = data.class01B.SubClass
                };

                var result = f.Subject.Save(item, Operation.Add);

                Assert.True(((Inprotech.Infrastructure.Validations.ValidationError[])result.Errors).Any());
                Assert.Equal("field.errors.uniqueItemCombination", result.Errors[0].Message);
            }
        }

        public class ClassItemPicklistMaintenanceFixture : IFixture<ClassItemsPicklistMaintenance>
        {
            readonly InMemoryDbContext _db;

            public ClassItemPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
                Subject = new ClassItemsPicklistMaintenance(_db, LastInternalCodeGenerator);
            }

            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; }

            public ClassItemsPicklistMaintenance Subject { get; }

            public dynamic SetupData()
            {
                var propertyType = new PropertyTypeBuilder
                {
                    AllowSubClass = 2m,
                    Id = "T",
                    Name = "Trademark"
                }.Build().In(_db);

                var @case = new CaseBuilder { Irn = "CHN-Case1", PropertyType = propertyType, CountryCode = "AF" }.Build().In(_db);

                var germanTableCode = new TableCodeBuilder
                {
                    Description = "German",
                    TableCode = Fixture.Integer(),
                    TableType = (short) TableTypes.Language,
                    UserCode = null
                }.Build().In(_db);

                var frenchTableCode = new TableCodeBuilder
                {
                    Description = "French",
                    TableCode = Fixture.Integer(),
                    TableType = (short)TableTypes.Language,
                    UserCode = null
                }.Build().In(_db);

                var class01 = new TmClass("AF", "01", propertyType.Name).In(_db);
                var class01B = new TmClass("AF", "01", propertyType.Name, 1) {SubClass = "B"}.In(_db);

                var undefinedItem01 = new InprotechKaizen.Model.Configuration.ClassItem("Undefined01", "Undefined Item for class 01", null, class01.Id)
                {
                    Class = class01,
                    Language = null
                }.In(_db);

                var definedItemDefault01 = new InprotechKaizen.Model.Configuration.ClassItem("Item01B", "Item01 for Class 01 SubClass B", null, class01B.Id)
                {
                    Class = class01B,
                    Language = null
                }.In(_db);
                
                var definedItemGerman01 = new InprotechKaizen.Model.Configuration.ClassItem("Item01B", "Item01 in German for Class 01 SubClass B", germanTableCode.Id, class01B.Id)
                {
                    Class = class01B,
                    Language = germanTableCode
                }.In(_db);

                var definedItemFrench01 = new InprotechKaizen.Model.Configuration.ClassItem("Item01B", "Item01 in French for Class 01 SubClass B", frenchTableCode.Id, class01B.Id)
                {
                    Class = class01B,
                    Language = frenchTableCode
                }.In(_db);

                return new
                {
                    @case,
                    class01,
                    class01B,
                    undefinedItem01,
                    definedItemDefault01,
                    definedItemGerman01,
                    definedItemFrench01,
                    germanTableCode,
                    frenchTableCode
                };
            }
        }
    }
}
