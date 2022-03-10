using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class EventOccurence : IntegrationTest
    {
        [Test]
        public void UpdateEventOccurence()
        {
            var data = DbSetup.Do(setup =>
            {
                var officeBuilder = new OfficeBuilder(setup.DbContext);
                var countryBuilder = new CountryBuilder(setup.DbContext);

                var office = officeBuilder.Create(Fixture.String(5));
                var caseType = setup.InsertWithNewId(new CaseType(Fixture.String(1), Fixture.String(5)));
                var country = countryBuilder.Create("country");
                var propertyType = setup.InsertWithNewId(new PropertyType {Name = Fixture.AlphaNumericString(8), Code = Fixture.AlphaNumericString(6)});
                var caseCategory = setup.Insert(new CaseCategory {Name = "base Case Catergory", CaseTypeId = caseType.Code, CaseCategoryId = "e2"});
                var subType = setup.InsertWithNewId(new SubType {Name = "base Sub Type"});
                var basis = setup.InsertWithNewId(new ApplicationBasis {Name = Fixture.String(5)});

                var fixture = new EventControlDbSetup().SetupCriteriaInheritance(new ValidEvent
                {
                    SyncedFromCaseOption = SyncedFromCaseOption.RelatedCase
                });

                return new
                {
                    fixture.EventId,
                    ParentId = fixture.CriteriaId,
                    ChildId = fixture.ChildCriteriaId,
                    fixture.Importance,
                    Office = office.Id,
                    CaseType = caseType.Code,
                    Country = country.Id,
                    PropertyType = propertyType.Code,
                    CaseCategory = caseCategory.CaseTypeId,
                    SubType = subType.Code,
                    Basis = basis.Code
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                UpdateEventImmediate = true,
                UpdateEventWhenDue = false,

                OfficeId = data.Office,
                CaseTypeId = data.CaseType,
                CountryCode = data.Country,
                PropertyTypeId = data.PropertyType,
                CaseCategoryId = data.CaseCategory,
                SubTypeId = data.SubType,
                BasisId = data.Basis
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.ParentId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ParentId && _.EventId == data.EventId);
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);

                Assert.AreEqual(formData.OfficeId, parent.OfficeId);
                Assert.AreEqual(formData.CaseTypeId, parent.CaseTypeId);
                Assert.AreEqual(formData.CountryCode, parent.CountryCode);
                Assert.AreEqual(formData.PropertyTypeId, parent.PropertyTypeId);
                Assert.AreEqual(formData.CaseCategoryId, parent.CaseCategoryId);
                Assert.AreEqual(formData.SubTypeId, parent.SubTypeId);
                Assert.AreEqual(formData.BasisId, parent.BasisId);

                Assert.AreEqual(formData.OfficeId, child.OfficeId);
                Assert.AreEqual(formData.CaseTypeId, child.CaseTypeId);
                Assert.AreEqual(formData.CountryCode, child.CountryCode);
                Assert.AreEqual(formData.PropertyTypeId, child.PropertyTypeId);
                Assert.AreEqual(formData.CaseCategoryId, child.CaseCategoryId);
                Assert.AreEqual(formData.SubTypeId, child.SubTypeId);
                Assert.AreEqual(formData.BasisId, child.BasisId);
            }
        }

        [Test]
        public void AddNameTypeMap()
        {
            var data = DbSetup.Do(setup =>
            {
                var inheritanceFixture = new EventControlDbSetup().SetupCriteriaInheritance();
                var nameTypeBuilder = new NameTypeBuilder(setup.DbContext);

                var existingChildNameTypeMap = new
                {
                    nameType = nameTypeBuilder.Create(),
                    substituteType = nameTypeBuilder.Create(),
                    mustExist = false
                };

                setup.Insert(new NameTypeMap(inheritanceFixture.ChildValidEvent,
                                             existingChildNameTypeMap.nameType.NameTypeCode,
                                             existingChildNameTypeMap.substituteType.NameTypeCode,
                                             0) {MustExist = existingChildNameTypeMap.mustExist});

                return new
                {
                    inheritanceFixture.EventId,
                    inheritanceFixture.CriteriaId,
                    ChildId = inheritanceFixture.ChildCriteriaId,
                    GrandchildId = inheritanceFixture.GrandchildCriteriaId,
                    inheritanceFixture.Importance,
                    ExistingChildNameTypeMap = existingChildNameTypeMap,
                    NameTypeMapToAdd = new
                    {
                        nameType = nameTypeBuilder.Create(),
                        substituteType = nameTypeBuilder.Create(),
                        mustExist = true
                    }
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                NameTypeMapDelta = new Delta<NameTypeMapSaveModel>
                {
                    Added = new List<NameTypeMapSaveModel>()
                }
            }.WithMandatoryFields();

            formData.NameTypeMapDelta.Added.Add(new NameTypeMapSaveModel
            {
                ApplicableNameTypeKey = data.NameTypeMapToAdd.nameType.NameTypeCode,
                SubstituteNameTypeKey = data.NameTypeMapToAdd.substituteType.NameTypeCode,
                MustExist = data.NameTypeMapToAdd.mustExist
            });
            formData.NameTypeMapDelta.Added.Add(new NameTypeMapSaveModel
            {
                ApplicableNameTypeKey = data.ExistingChildNameTypeMap.nameType.NameTypeCode,
                SubstituteNameTypeKey = data.ExistingChildNameTypeMap.substituteType.NameTypeCode,
                MustExist = !data.ExistingChildNameTypeMap.mustExist
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentNameTypeMaps = dbContext.Set<ValidEvent>()
                                                  .Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId)
                                                  .NameTypeMaps;
                var childNameTypeMaps = dbContext.Set<ValidEvent>()
                                                 .Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId)
                                                 .NameTypeMaps;
                var grandchildNameTypeMaps = dbContext.Set<ValidEvent>()
                                                      .Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId)
                                                      .NameTypeMaps;

                Assert.AreEqual(2, parentNameTypeMaps.Count, "Adds new name type maps");
                Assert.AreEqual(1, childNameTypeMaps.Count(_ => _.Inherited), "Adds name type map in child , not already present");
                Assert.AreEqual(1, childNameTypeMaps.Count(_ => !_.Inherited), "Name type map in child continues to have previous non inherited map");

                var childInheritedNameTypeMap = childNameTypeMaps.Single(_ => _.Inherited);
                Assert.AreEqual(data.NameTypeMapToAdd.nameType.NameTypeCode, childInheritedNameTypeMap.ApplicableNameType.NameTypeCode, "Adds correct name type map in child - Applicable name");
                Assert.AreEqual(data.NameTypeMapToAdd.substituteType.NameTypeCode, childInheritedNameTypeMap.SubstituteNameType.NameTypeCode, "Adds correct name type map in child - Substitute name");
                Assert.AreEqual(data.NameTypeMapToAdd.mustExist, childInheritedNameTypeMap.MustExist, "Adds correct name type map in child - must exist");

                var childNonInheritedNameTypeMap = childNameTypeMaps.Single(_ => !_.Inherited);
                Assert.AreEqual(data.ExistingChildNameTypeMap.nameType.NameTypeCode, childNonInheritedNameTypeMap.ApplicableNameType.NameTypeCode, "Existing name type map in child continues to have correct Applicable name");
                Assert.AreEqual(data.ExistingChildNameTypeMap.substituteType.NameTypeCode, childNonInheritedNameTypeMap.SubstituteNameType.NameTypeCode, "Existing name type map in child continues to have correct Substitute name");
                Assert.AreEqual(data.ExistingChildNameTypeMap.mustExist, childNonInheritedNameTypeMap.MustExist, "Existing name type map in child continues to have correct must exist");

                Assert.AreEqual(1, grandchildNameTypeMaps.Count(_ => _.Inherited), "Adds name type map in grandchild , not already present");
                Assert.AreEqual(0, grandchildNameTypeMaps.Count(_ => !_.Inherited), "Grandchild does not have any non inherited name type maps");

                var grandChildNameTypeMap = grandchildNameTypeMaps.Single(_ => _.Inherited);
                Assert.AreEqual(data.NameTypeMapToAdd.nameType.NameTypeCode, grandChildNameTypeMap.ApplicableNameType.NameTypeCode, "Adds correct name type map in child - Applicable name");
                Assert.AreEqual(data.NameTypeMapToAdd.substituteType.NameTypeCode, grandChildNameTypeMap.SubstituteNameType.NameTypeCode, "Adds correct name type map in child - Substitute name");
                Assert.AreEqual(data.NameTypeMapToAdd.mustExist, grandChildNameTypeMap.MustExist, "Adds correct name type map in child - must exist");
            }
        }

        [Test]
        public void UpdateNameTypeMap()
        {
            var data = DbSetup.Do(setup =>
            {
                var inheritanceFixture = new EventControlDbSetup().SetupCriteriaInheritance();
                var nameTypeBuilder = new NameTypeBuilder(setup.DbContext);

                var existingNameTypeMap = new
                {
                    nameType = nameTypeBuilder.Create(),
                    substituteType = nameTypeBuilder.Create(),
                    mustExist = false
                };

                setup.Insert(new NameTypeMap(inheritanceFixture.CriteriaValidEvent,
                                             existingNameTypeMap.nameType.NameTypeCode,
                                             existingNameTypeMap.substituteType.NameTypeCode,
                                             0)
                {
                    MustExist = existingNameTypeMap.mustExist
                });

                setup.Insert(new NameTypeMap(inheritanceFixture.ChildValidEvent,
                                             existingNameTypeMap.nameType.NameTypeCode,
                                             existingNameTypeMap.substituteType.NameTypeCode,
                                             0)
                {
                    MustExist = existingNameTypeMap.mustExist,
                    Inherited = true
                });

                setup.Insert(new NameTypeMap(inheritanceFixture.GrandchildValidEvent,
                                             existingNameTypeMap.nameType.NameTypeCode,
                                             existingNameTypeMap.substituteType.NameTypeCode,
                                             0)
                {
                    MustExist = !existingNameTypeMap.mustExist,
                    Inherited = false
                });

                return new
                {
                    inheritanceFixture.EventId,
                    inheritanceFixture.CriteriaId,
                    ChildId = inheritanceFixture.ChildCriteriaId,
                    GrandchildId = inheritanceFixture.GrandchildCriteriaId,
                    inheritanceFixture.Importance,
                    ExistingNameTypeMap = existingNameTypeMap,
                    NameTypeMapToUpdate = new
                    {
                        nameType = nameTypeBuilder.Create(),
                        mustExist = true
                    }
                };
            });

            var update = new NameTypeMapSaveModel
            {
                Sequence = 0,
                ApplicableNameTypeKey = data.NameTypeMapToUpdate.nameType.NameTypeCode,
                SubstituteNameTypeKey = data.ExistingNameTypeMap.substituteType.NameTypeCode,
                MustExist = data.NameTypeMapToUpdate.mustExist
            };

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                NameTypeMapDelta = new Delta<NameTypeMapSaveModel>
                {
                    Updated = new List<NameTypeMapSaveModel> {update}
                }
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentNameTypeMaps = dbContext.Set<ValidEvent>()
                                                  .Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId)
                                                  .NameTypeMaps;
                var childNameTypeMaps = dbContext.Set<ValidEvent>()
                                                 .Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId)
                                                 .NameTypeMaps;
                var grandchildNameTypeMaps = dbContext.Set<ValidEvent>()
                                                      .Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId)
                                                      .NameTypeMaps;

                var parentNameTypeMap = parentNameTypeMaps.Single();
                Assert.AreEqual(update.ApplicableNameTypeKey, parentNameTypeMap.ApplicableNameType.NameTypeCode, "Updates name type map in parent - Applicable name");
                Assert.AreEqual(update.SubstituteNameTypeKey, parentNameTypeMap.SubstituteNameType.NameTypeCode, "Updates name type map in parent - Substitute name");
                Assert.AreEqual(update.MustExist, parentNameTypeMap.MustExist, "Updates name type map in parent - must exist");

                Assert.AreEqual(1, childNameTypeMaps.Count(_ => _.Inherited), "Name type map in child - remains inherited");

                var childNameTypeMap = childNameTypeMaps.Single(_ => _.Inherited);
                Assert.AreEqual(update.ApplicableNameTypeKey, childNameTypeMap.ApplicableNameType.NameTypeCode, "Updates name type map in child - Applicable name");
                Assert.AreEqual(update.SubstituteNameTypeKey, childNameTypeMap.SubstituteNameType.NameTypeCode, "Updates name type map in child - Substitute name");
                Assert.AreEqual(update.MustExist, childNameTypeMap.MustExist, "Updates name type map in child - must exist");

                Assert.AreEqual(1, grandchildNameTypeMaps.Count(_ => !_.Inherited), "Grandchild continues to have single non inherited name type maps");

                var grandChildNameTypeMap = grandchildNameTypeMaps.Single();
                Assert.AreEqual(data.ExistingNameTypeMap.nameType.NameTypeCode, grandChildNameTypeMap.ApplicableNameType.NameTypeCode, "Keeps name type map in grandchild, as its not inherited - Applicable name");
                Assert.AreEqual(data.ExistingNameTypeMap.substituteType.NameTypeCode, grandChildNameTypeMap.SubstituteNameType.NameTypeCode, "Keeps name type map in grandchild, as its not inherited - Substitute name");
                Assert.AreEqual(!data.ExistingNameTypeMap.mustExist, grandChildNameTypeMap.MustExist, "Keeps name type map in grandchild, as its not inherited - must exist");
            }
        }

        [Test]
        public void DeleteNameTypeMap()
        {
            var data = DbSetup.Do(setup =>
            {
                var inheritanceFixture = new EventControlDbSetup().SetupCriteriaInheritance();
                var nameTypeBuilder = new NameTypeBuilder(setup.DbContext);

                var existingNameTypeMap1 = new
                {
                    nameType = nameTypeBuilder.Create(),
                    substituteType = nameTypeBuilder.Create(),
                    mustExist = false
                };

                var existingNameTypeMap2 = new
                {
                    nameType = existingNameTypeMap1.substituteType,
                    substituteType = nameTypeBuilder.Create(),
                    mustExist = false
                };

                setup.Insert(new NameTypeMap(inheritanceFixture.CriteriaValidEvent,
                                             existingNameTypeMap1.nameType.NameTypeCode,
                                             existingNameTypeMap1.substituteType.NameTypeCode,
                                             0)
                {
                    MustExist = existingNameTypeMap1.mustExist
                });

                setup.Insert(new NameTypeMap(inheritanceFixture.CriteriaValidEvent,
                                             existingNameTypeMap2.nameType.NameTypeCode,
                                             existingNameTypeMap2.substituteType.NameTypeCode,
                                             1)
                {
                    MustExist = existingNameTypeMap2.mustExist
                });

                setup.Insert(new NameTypeMap(inheritanceFixture.ChildValidEvent,
                                             existingNameTypeMap1.nameType.NameTypeCode,
                                             existingNameTypeMap1.substituteType.NameTypeCode,
                                             0)
                {
                    MustExist = existingNameTypeMap1.mustExist,
                    Inherited = true
                });
                setup.Insert(new NameTypeMap(inheritanceFixture.ChildValidEvent,
                                             existingNameTypeMap2.nameType.NameTypeCode,
                                             existingNameTypeMap2.substituteType.NameTypeCode,
                                             1)
                {
                    MustExist = existingNameTypeMap2.mustExist,
                    Inherited = false
                });

                setup.Insert(new NameTypeMap(inheritanceFixture.GrandchildValidEvent,
                                             existingNameTypeMap1.nameType.NameTypeCode,
                                             existingNameTypeMap1.substituteType.NameTypeCode,
                                             0)
                {
                    MustExist = existingNameTypeMap1.mustExist,
                    Inherited = true
                });
                setup.Insert(new NameTypeMap(inheritanceFixture.GrandchildValidEvent,
                                             existingNameTypeMap2.nameType.NameTypeCode,
                                             existingNameTypeMap2.substituteType.NameTypeCode,
                                             1)
                {
                    MustExist = existingNameTypeMap2.mustExist,
                    Inherited = true
                });

                return new
                {
                    inheritanceFixture.EventId,
                    inheritanceFixture.CriteriaId,
                    ChildId = inheritanceFixture.ChildCriteriaId,
                    GrandchildId = inheritanceFixture.GrandchildCriteriaId,
                    inheritanceFixture.Importance,
                    ExistingNameTypeMap1 = existingNameTypeMap1,
                    ExistingNameTypeMap2 = existingNameTypeMap2
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                NameTypeMapDelta = new Delta<NameTypeMapSaveModel>
                {
                    Deleted = new List<NameTypeMapSaveModel>
                    {
                        new NameTypeMapSaveModel
                        {
                            ApplicableNameTypeKey = data.ExistingNameTypeMap1.nameType.NameTypeCode,
                            SubstituteNameTypeKey = data.ExistingNameTypeMap1.substituteType.NameTypeCode,
                            MustExist = data.ExistingNameTypeMap1.mustExist,
                            Sequence = 0
                        },
                        new NameTypeMapSaveModel
                        {
                            ApplicableNameTypeKey = data.ExistingNameTypeMap2.nameType.NameTypeCode,
                            SubstituteNameTypeKey = data.ExistingNameTypeMap2.substituteType.NameTypeCode,
                            MustExist = data.ExistingNameTypeMap2.mustExist,
                            Sequence = 1
                        }
                    }
                }
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentCount = dbContext.Set<NameTypeMap>().Count(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var childCount = dbContext.Set<NameTypeMap>().Count(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var grandchildCount = dbContext.Set<NameTypeMap>().Count(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(0, parentCount, "Deletes name type maps.");
                Assert.AreEqual(1, childCount, "Deletes Inherited name type maps, but keeps non inhertited name type maps");
                Assert.AreEqual(1, grandchildCount, "Deletes only the inherited name type maps from grand parent");
            }
        }

        [Test]
        public void AddEventMustExist()
        {
            var data = DbSetup.Do(setup =>
            {
                var inheritanceFixture = new EventControlDbSetup().SetupCriteriaInheritance();

                var childExistingReqEvent = setup.InsertWithNewId(new Event());
                setup.Insert(new RequiredEventRule(inheritanceFixture.ChildValidEvent){RequiredEvent = childExistingReqEvent });

                var newReqEvent = setup.InsertWithNewId(new Event());

                return new
                {
                    inheritanceFixture.EventId,
                    inheritanceFixture.CriteriaId,
                    ChildId = inheritanceFixture.ChildCriteriaId,
                    GrandchildId = inheritanceFixture.GrandchildCriteriaId,
                    inheritanceFixture.Importance,
                    ChildExistingReqEvent = childExistingReqEvent,
                    NewReqEvent = newReqEvent
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                ChangeRespOnDueDates = false,
                RequiredEventRulesDelta = new Delta<int>
                {
                    Added = new List<int>
                    {
                        data.ChildExistingReqEvent.Id,
                        data.NewReqEvent.Id
                    }
                }
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentEventsMustExist = dbContext.Set<RequiredEventRule>().Where(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var childEventsMustExist = dbContext.Set<RequiredEventRule>().Where(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var grandchildEventsMustExist = dbContext.Set<RequiredEventRule>().Where(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(2, parentEventsMustExist.Count(), "Adds new events must exist");

                Assert.AreEqual(1, childEventsMustExist.Count(_=>_.Inherited), "Adds events must exist to child, if not already there");
                Assert.AreEqual(data.NewReqEvent.Id, childEventsMustExist.Single(_ => _.Inherited).RequiredEventId, "Adds correct event must exist to child, if not already there");

                Assert.AreEqual(1, childEventsMustExist.Count(_ => !_.Inherited), "Does not add events must exist to child, if already there");
                Assert.AreEqual(data.ChildExistingReqEvent.Id, childEventsMustExist.Single(_ => !_.Inherited).RequiredEventId, "Keeps correct event must exist to child, since already there");

                Assert.AreEqual(1, grandchildEventsMustExist.Count(), "Adds events must exists grandchild, which was added in child");
                Assert.AreEqual(data.NewReqEvent.Id, grandchildEventsMustExist.Single().RequiredEventId, "Adds correct event must exist to grandchild");
            }
        }

        [Test]
        public void DeleteEventMustExist()
        {
            var data = DbSetup.Do(setup =>
            {
                var inheritanceFixture = new EventControlDbSetup().SetupCriteriaInheritance();

                var existingReqEvent1 = setup.InsertWithNewId(new Event());
                var existingReqEvent2 = setup.InsertWithNewId(new Event());

                setup.Insert(new RequiredEventRule(inheritanceFixture.CriteriaValidEvent) { RequiredEvent = existingReqEvent1 });
                setup.Insert(new RequiredEventRule(inheritanceFixture.CriteriaValidEvent) { RequiredEvent = existingReqEvent2 });

                setup.Insert(new RequiredEventRule(inheritanceFixture.ChildValidEvent) { RequiredEvent = existingReqEvent1, Inherited = true });
                setup.Insert(new RequiredEventRule(inheritanceFixture.ChildValidEvent) { RequiredEvent = existingReqEvent2, Inherited = false });

                setup.Insert(new RequiredEventRule(inheritanceFixture.GrandchildValidEvent) { RequiredEvent = existingReqEvent1 , Inherited = true});
                setup.Insert(new RequiredEventRule(inheritanceFixture.GrandchildValidEvent) { RequiredEvent = existingReqEvent2, Inherited = true });

                return new
                {
                    inheritanceFixture.EventId,
                    inheritanceFixture.CriteriaId,
                    ChildId = inheritanceFixture.ChildCriteriaId,
                    GrandchildId = inheritanceFixture.GrandchildCriteriaId,
                    inheritanceFixture.Importance,
                    ExistingReqEvent1 = existingReqEvent1,
                    ExistingReqEvent2 = existingReqEvent2,
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                ChangeRespOnDueDates = false,
                RequiredEventRulesDelta = new Delta<int>
                {
                    Deleted = new List<int>
                    {
                        data.ExistingReqEvent1.Id,
                        data.ExistingReqEvent2.Id
                    }
                }
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentEventsMustExist = dbContext.Set<RequiredEventRule>().Where(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var childEventsMustExist = dbContext.Set<RequiredEventRule>().Where(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var grandchildEventsMustExist = dbContext.Set<RequiredEventRule>().Where(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(0, parentEventsMustExist.Count(), "Deletes new events must exist");

                Assert.AreEqual(1, childEventsMustExist.Count(), "Delets inherited events must exist from child");
                Assert.AreEqual(data.ExistingReqEvent2.Id, childEventsMustExist.Single().RequiredEventId, "Keeps correct event must exist in child, since not inherited");

                Assert.AreEqual(1, grandchildEventsMustExist.Count(), "Deletes single inherited events must exist from grandchild, since deleted from child");
                Assert.AreEqual(data.ExistingReqEvent2.Id, grandchildEventsMustExist.Single().RequiredEventId, "Keeps correct event must exist in child, since inherited but not deleted from child");
            }
        }
    }
}