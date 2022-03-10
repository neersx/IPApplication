using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration.BulkCaseUpdates;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.GlobalCaseChange;
using Xunit;

namespace Inprotech.Tests.Integration.BulkCaseUpdates
{
    public class BulkCaseNameReferenceUpdateHandlerFacts : FactBase
    {
        dynamic SetData()
        {
            var c1 = new CaseBuilder().Build().In(Db);
            var c2 = new CaseBuilder().Build().In(Db);
            var process = new BackgroundProcess { ProcessType = BackgroundProcessType.GlobalCaseChange.ToString() }.In(Db);
            var textType = new TextTypeBuilder().Build().In(Db);
            var nameType = new NameTypeBuilder().Build().In(Db);
            var nameType2 = new NameTypeBuilder().Build().In(Db);
            var caseName = new CaseNameBuilder(Db){ NameType = nameType}.BuildWithCase(c1).In(Db);
            var caseName2 = new CaseNameBuilder(Db){ NameType = nameType2}.BuildWithCase(c2).In(Db);
            var gncResult1 = new GlobalCaseChangeResults {Id = process.Id, CaseId = c1.Id}.In(Db);
            var gncResult2 = new GlobalCaseChangeResults {Id = process.Id, CaseId = c2.Id}.In(Db);
            var gncResults = new List<GlobalCaseChangeResults> {gncResult1, gncResult2}.AsQueryable();
            return new
            {
                c1,
                c2,
                ProcessId = process.Id,
                textType,
                nameType,
                caseName,
                caseName2,
                gncResults
            };
        }

        dynamic SetHierarchyData()
        {
            var c1 = new CaseBuilder().Build().In(Db);
            var process = new BackgroundProcess { ProcessType = BackgroundProcessType.GlobalCaseChange.ToString() }.In(Db);
            var textType = new TextTypeBuilder().Build().In(Db);
            var name = new NameBuilder(Db).Build().In(Db);
            var nameType = new NameTypeBuilder { NameTypeCode = "I", Name = "Instructor"}.Build().In(Db);
            var nameTypeDebtor = new NameTypeBuilder { HierarchyFlag = 1, PathNameType = "I", NameTypeCode = "D", Name = "Debtor"}.Build().In(Db);
            var nameTypeRenewalDebtor = new NameTypeBuilder { HierarchyFlag = 0, PathNameType = "I", NameTypeCode = "Z", Name = "Renewals Debtor"}.Build().In(Db);
            var grandChildNameType = new NameTypeBuilder { HierarchyFlag = 1, PathNameType = "D", NameTypeCode = "CD", Name = "Debtor Copies To"}.Build().In(Db);
            var caseName1 = new CaseNameBuilder(Db){ NameType = nameType, Name = name}.BuildWithCase(c1).In(Db);
            var caseName2 = new CaseNameBuilder(Db){ NameType = nameTypeDebtor, Name = name}.BuildWithCase(c1,1).In(Db);
            var caseName3 = new CaseNameBuilder(Db){ NameType = nameTypeRenewalDebtor, Name = name}.BuildWithCase(c1,0).In(Db);
            var caseName4 = new CaseNameBuilder(Db){ NameType = grandChildNameType, Name = name}.BuildWithCase(c1,1).In(Db);
            var gncResult1 = new GlobalCaseChangeResults {Id = process.Id, CaseId = c1.Id}.In(Db);
            var gncResults = new List<GlobalCaseChangeResults> {gncResult1}.AsQueryable();
            return new
            {
                c1,
                ProcessId = process.Id,
                textType,
                nameType,
                caseName1,
                caseName2,
                caseName3,
                caseName4,
                gncResults
            };  
        }       
                
        [Fact]
        public async Task ShouldSuccessfullyExecuteBulkFieldUpdate()
        {
            var f = new BulkCaseNameReferenceUpdateHandlerFixture(Db);
            var data = SetData();
            var cases = new Case[] {data.c1, data.c2};
            var request = new BulkCaseUpdatesArgs
            {
                ProcessId = data.ProcessId,
                CaseIds = new[] { (int)data.c1.Id, (int)data.c2.Id },
                SaveData = new BulkUpdateData
                {
                    CaseNameReference = new BulkCaseNameReferenceUpdate { NameType = data.nameType.NameTypeCode, Reference = Fixture.String("ref"), ToRemove = false}
                },
                TextType = data.textType.Id,
                Notes = Fixture.String("Notes")
            };
            await f.Subject.UpdateNameTypeAsync(request, cases.AsQueryable(), data.gncResults);

            var caseName= Db.Set<CaseName>().ToArray().SingleOrDefault(_ => _.NameTypeId == data.nameType.NameTypeCode && _.CaseId == (int)data.c1.Id);
            var caseName2= Db.Set<CaseName>().ToArray().SingleOrDefault(_ => _.NameTypeId == data.nameType.NameTypeCode && _.CaseId == (int)data.c2.Id);
            Assert.NotNull(caseName);
            Assert.Equal(caseName.Reference, request.SaveData.CaseNameReference.Reference);
            Assert.Null(caseName2);
        }

        [Fact]
        public async Task ShouldSuccessfullyBulkCaseUpdateForInheritedNameType()
        {
            var f = new BulkCaseNameReferenceUpdateHandlerFixture(Db);
            var data = SetHierarchyData();
            var cases = new Case[] {data.c1};
            var request = new BulkCaseUpdatesArgs
            {
                ProcessId = data.ProcessId,
                CaseIds = new[] {(int) data.c1.Id},
                SaveData = new BulkUpdateData
                {
                    CaseNameReference = new BulkCaseNameReferenceUpdate {NameType = data.nameType.NameTypeCode, Reference = Fixture.String("ref"), ToRemove = false}
                },
                TextType = data.textType.Id,
                Notes = Fixture.String("Notes")
            };
            await f.Subject.UpdateNameTypeAsync(request, cases.AsQueryable(), data.gncResults);
            
            var caseNames = Db.Set<CaseName>().Where(_ => _.CaseId == request.CaseIds[0] && _.NameTypeId != "Z").ToArray();
            Assert.True(caseNames.All(_=>_.Reference == request.SaveData.CaseNameReference.Reference));
        }

        [Fact]
        public async Task ShouldSuccessfullyBulkCaseRemoveForInheritedNameType()
        {
            var f = new BulkCaseNameReferenceUpdateHandlerFixture(Db);
            var data = SetHierarchyData();
            var cases = new Case[] {data.c1};
            var request = new BulkCaseUpdatesArgs
            {
                ProcessId = data.ProcessId,
                CaseIds = new[] { (int)data.c1.Id},
                SaveData = new BulkUpdateData
                {
                    CaseNameReference = new BulkCaseNameReferenceUpdate { NameType = data.nameType.NameTypeCode , ToRemove = true}
                },
                TextType = data.textType.Id,
                Notes = Fixture.String("Notes")
            };
            await f.Subject.UpdateNameTypeAsync(request, cases.AsQueryable(), data.gncResults);

            var caseNames = Db.Set<CaseName>().Where(_ => _.CaseId == request.CaseIds[0] && _.NameTypeId != "Z").ToArray();
            Assert.True(caseNames.All(_=>_.Reference == string.Empty));
        }
    }

    public class BulkCaseNameReferenceUpdateHandlerFixture : IFixture<BulkCaseNameReferenceUpdateHandler>
    {
        public BulkCaseNameReferenceUpdateHandler Subject { get; set; }

        public BulkCaseNameReferenceUpdateHandlerFixture(InMemoryDbContext db)
        {
           
            Subject = new BulkCaseNameReferenceUpdateHandler(db);
        }
    }
}
