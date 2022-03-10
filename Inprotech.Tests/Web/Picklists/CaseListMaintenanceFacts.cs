using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using NSubstitute;
using Xunit;
using Case = Inprotech.Web.Picklists.Case;
using CaseList = InprotechKaizen.Model.Cases.CaseList;

namespace Inprotech.Tests.Web.Picklists
{
    public class CaseListMaintenanceFacts
    {
        public class GetCaseListsMethod : FactBase
        {
            [Fact]
            public void ReturnsCaseListsWithPrimeCaseIfAny()
            {
                var case1 = new CaseBuilder().BuildWithId(1).In(Db);
                var caseList1 = new CaseList { Description = "cs1", Name = "cs1" }.In(Db);
                var caseList2 = new CaseList { Description = "cs2", Name = "cs2" }.In(Db);
                new CaseListMember(caseList1.Id, case1, true).In(Db);
                new CaseListMember(caseList2.Id, case1, false).In(Db);

                var f = new CaseListMaintenanceFixture(Db);
                var caseLists = f.Subject.GetCaseLists().ToArray();

                var caseListWithPrimeCase = caseLists.Where(_ => _.PrimeCase != null).ToArray();

                Assert.Equal(2, caseLists.Count());
                Assert.Equal(1, caseListWithPrimeCase.Length);
                Assert.Equal(case1.Irn, caseListWithPrimeCase.Single().PrimeCase.Value);
                Assert.Equal(caseList1.Id, caseListWithPrimeCase.Single().Key);
                Assert.Equal(caseList1.Description, caseListWithPrimeCase.Single().Value);
            }
        }

        public class GetCasesMethod : FactBase
        {
            [Fact]
            public void ReturnsCaseListItemsByProvidedCaseKeys()
            {
                var case1 = new CaseBuilder().BuildWithId(1).In(Db);
                var case2 = new CaseBuilder().BuildWithId(2).In(Db);
                var case3 = new CaseBuilder().BuildWithId(3).In(Db);

                var f = new CaseListMaintenanceFixture(Db);
                var caseListItems = f.Subject.GetCases(new[] { case1.Id, case3.Id }, null, new[] { case3.Id }).ToArray();

                Assert.Equal(2, caseListItems.Count());
                Assert.Equal(case3.Id, caseListItems.First().CaseKey);
                Assert.Null(caseListItems.SingleOrDefault(_ => _.CaseKey == case2.Id));
            }

            [Fact]
            public void ReturnsCaseListItemsWithPrimeCase()
            {
                var case1 = new CaseBuilder().BuildWithId(1).In(Db);
                var case2 = new CaseBuilder().BuildWithId(2).In(Db);
                var case3 = new CaseBuilder().BuildWithId(3).In(Db);

                var f = new CaseListMaintenanceFixture(Db);
                var caseListItems = f.Subject.GetCases(new[] { case1.Id, case3.Id, case2.Id }, case2.Id, null).ToArray();

                Assert.Equal(3, caseListItems.Count());
                Assert.Equal(case2.Id, caseListItems.Single(_ => _.IsPrimeCase).CaseKey);
            }
        }

        public class GetCaseListMethod : FactBase
        {
            [Fact]
            public void ReturnsCaseListById()
            {
                var case1 = new CaseBuilder().BuildWithId(1).In(Db);
                var caseList1 = new CaseList { Description = "cs1", Name = "cs1" }.In(Db);
                var caseList2 = new CaseList { Description = "cs2", Name = "cs2" }.In(Db);
                new CaseListMember(caseList1.Id, case1, true).In(Db);
                new CaseListMember(caseList2.Id, case1, false).In(Db);

                var f = new CaseListMaintenanceFixture(Db);
                var result = f.Subject.GetCaseList(caseList1.Id);
                Assert.Equal(caseList1.Id, result.Key);
                Assert.Equal(case1.Id, result.PrimeCase.Key);
            }

            [Fact]
            public void ReturnsException()
            {
                var f = new CaseListMaintenanceFixture(Db);
                Assert.Throws<ArgumentNullException>(() => f.Subject.GetCaseList(1));
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ReturnsException()
            {
                var f = new CaseListMaintenanceFixture(Db);
                Assert.Throws<ArgumentNullException>(() => f.Subject.Delete(1));
            }

            [Fact]
            public void ReturnsInUseMessage()
            {
                var caseList1 = new CaseList { Description = "cs1", Name = "cs1" }.In(Db);
                var priorArt = new InprotechKaizen.Model.PriorArt.PriorArt().In(Db);
                new CaseListSearchResult { CaseListId = caseList1.Id, PriorArtId = priorArt.Id }.In(Db);

                var f = new CaseListMaintenanceFixture(Db);
                var result = f.Subject.Delete(caseList1.Id);
                var error = (ValidationError[]) result.Errors;
                Assert.Equal("entity.cannotdelete", error.First().Message);
            }

            [Fact]
            public void ReturnsSuccess()
            {
                var caseList1 = new CaseList { Description = "cs1", Name = "cs1" }.In(Db);
                var f = new CaseListMaintenanceFixture(Db);
                var result = f.Subject.Delete(caseList1.Id);

                Assert.Equal("success", result.Result);
            }
            
            [Fact]
            public void ReturnsSuccessForMultipleCaseList()
            {
                var caseList1 = new CaseList { Description = "cs1", Name = "cs1" }.In(Db);
                var caseList2 = new CaseList { Description = "cs1", Name = "cs1" }.In(Db);
                var f = new CaseListMaintenanceFixture(Db);
                var result = f.Subject.Delete(new List<int>() { caseList1.Id, caseList2.Id });
                
                Assert.Equal("success", result.Result);
                Assert.Equal(0, result.CannotDeleteCaselistIds.Count);
            }

            [Fact]
            public void ReturnsPartialCompleteMessageForMultipleCaseList()
            {
                var caseList1 = new CaseList { Description = "cs1", Name = "cs1" }.In(Db);
                var caseList2 = new CaseList { Description = "cs1", Name = "cs1" }.In(Db);
                var priorArt = new InprotechKaizen.Model.PriorArt.PriorArt().In(Db);
                new CaseListSearchResult { CaseListId = caseList1.Id, PriorArtId = priorArt.Id }.In(Db);

                var f = new CaseListMaintenanceFixture(Db);
                var result = f.Subject.Delete(new List<int> { caseList1.Id, caseList2.Id });
                Assert.Equal("partialComplete", result.Result);
                Assert.Equal(1, result.CannotDeleteCaselistIds.Count);
                Assert.Equal(caseList1.Id,((List<int>) result.CannotDeleteCaselistIds).First());
            }

            [Fact]
            public void ReturnsErrorMessageForMultipleCaseList()
            {
                var caseList1 = new CaseList { Description = "cs1", Name = "cs1" }.In(Db);
                var caseList2 = new CaseList { Description = "cs1", Name = "cs1" }.In(Db);
                var priorArt1 = new InprotechKaizen.Model.PriorArt.PriorArt().In(Db);
                var priorArt2 = new InprotechKaizen.Model.PriorArt.PriorArt().In(Db);
                new CaseListSearchResult { CaseListId = caseList1.Id, PriorArtId = priorArt1.Id }.In(Db);
                new CaseListSearchResult { CaseListId = caseList2.Id, PriorArtId = priorArt2.Id }.In(Db);

                var f = new CaseListMaintenanceFixture(Db);
                var result = f.Subject.Delete(new List<int>() { caseList1.Id, caseList2.Id });
                Assert.Equal("error", result.Result);
                Assert.Equal(2, result.CannotDeleteCaselistIds.Count);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ReturnsDuplicateMessage()
            {
                var caseList1 = new CaseList { Description = "cs1", Name = "cs1" }.In(Db);

                var caseList = new Inprotech.Web.Picklists.CaseList
                {
                    Value = caseList1.Name,
                    Key = Fixture.Integer()
                };

                var f = new CaseListMaintenanceFixture(Db);
                var result = f.Subject.Save(caseList);
                var error = (ValidationError[]) result.Errors;
                Assert.Equal("field.errors.notunique", error.First().Message);
            }

            [Fact]
            public void ReturnsExceptionWhenModelIsNull()
            {
                var f = new CaseListMaintenanceFixture(Db);
                Assert.Throws<ArgumentNullException>(() => f.Subject.Save(null));
            }

            [Fact]
            public void ReturnsExceptionWhenValueNull()
            {
                var f = new CaseListMaintenanceFixture(Db);
                Assert.Throws<ArgumentNullException>(() => f.Subject.Save(new Inprotech.Web.Picklists.CaseList { Value = null }));
            }

            [Fact]
            public void ReturnsSuccessWithNewCaseListId()
            {
                var @case = new CaseBuilder().BuildWithId(1).In(Db);
                new CaseBuilder().BuildWithId(2).In(Db);
                new CaseBuilder().BuildWithId(3).In(Db);

                var caseList = new Inprotech.Web.Picklists.CaseList
                {
                    Value = Fixture.String(),
                    Key = Fixture.Integer(),
                    Description = Fixture.String(),
                    PrimeCase = new Case
                    {
                        Key = 1,
                        Code = @case.Irn
                    },
                    CaseKeys = new[] { 2, 3, 1 }
                };
                var f = new CaseListMaintenanceFixture(Db);
                var result = f.Subject.Save(caseList);
                Assert.Equal("success", result.Result);
                Assert.NotNull(result.Key);
                int newId = result.Key;
                var insertCaseList = Db.Set<CaseList>().SingleOrDefault(_ => _.Id == newId);
                Assert.NotNull(insertCaseList);
                var members = Db.Set<CaseListMember>().Where(_ => _.Id == newId);
                Assert.NotNull(members);
                Assert.Equal(3, members.ToList().Count);
                Assert.Equal(1, members.Single(_ => _.IsPrimeCase).CaseId);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ReturnsExceptionWhenIdIsNull()
            {
                var f = new CaseListMaintenanceFixture(Db);
                Assert.Throws<ArgumentNullException>(() => f.Subject.Update(-1, new Inprotech.Web.Picklists.CaseList()));
            }

            [Fact]
            public void ReturnsExceptionWhenModelIsNull()
            {
                var f = new CaseListMaintenanceFixture(Db);
                Assert.Throws<ArgumentNullException>(() => f.Subject.Update(1, null));
            }

            [Fact]
            public void ReturnsSuccessWithCaseListId()
            {
                var @case = new CaseBuilder().BuildWithId(1).In(Db);
                var case2 = new CaseBuilder().BuildWithId(2).In(Db);
                var case3 = new CaseBuilder().BuildWithId(3).In(Db);
                var caseList1 = new CaseList { Description = "cs1", Name = "cs1" }.In(Db);
                new CaseListMember(caseList1.Id, @case, false).In(Db);
                new CaseListMember(caseList1.Id, case2, false).In(Db);

                var caseList = new Inprotech.Web.Picklists.CaseList
                {
                    Value = caseList1.Name,
                    Key = caseList1.Id,
                    Description = "updated case list",
                    PrimeCase = new Case
                    {
                        Key = case3.Id,
                        Code = case3.Irn
                    },
                    CaseKeys = new[] { 2, 3, 1 }
                };
                var f = new CaseListMaintenanceFixture(Db);
                var result = f.Subject.Update(caseList1.Id, caseList);
                Assert.Equal("success", result.Result);
                Assert.NotNull(result.Key);
                int newId = result.Key;
                var updatedCaseList = Db.Set<CaseList>().SingleOrDefault(_ => _.Id == newId);
                Assert.NotNull(updatedCaseList);
                var members = Db.Set<CaseListMember>().Where(_ => _.Id == newId);
                Assert.NotNull(members);
                Assert.Equal(3, members.ToList().Count);
                Assert.Equal(case3.Id, members.Single(_ => _.IsPrimeCase).CaseId);
            }
        }
    }

    public class CaseListMaintenanceFixture : IFixture<CaseListMaintenance>
    {
        public CaseListMaintenanceFixture(InMemoryDbContext db)
        {
            LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();
            LastInternalCodeGenerator.GenerateLastInternalCode("CASELIST").Returns(1);
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            PreferredCultureResolver.Resolve().Returns("en-US");
            Subject = new CaseListMaintenance(db, PreferredCultureResolver, LastInternalCodeGenerator);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }

        public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }
        public CaseListMaintenance Subject { get; }
    }
}