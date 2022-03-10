using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;

namespace Inprotech.Tests.Integration.DbHelpers
{
    public static class AccountingDbHelper
    {
        public static void SetupCaseOfficeEntity(bool forFailure, bool canDefaultFromCaseOfficeEntity)
        {
            DbSetup.Do(x =>
            {
                var nonEntityOrg = new NameBuilder(x.DbContext).CreateOrg(NameUsedAs.Organisation);
                var @case = new CaseBuilder(x.DbContext).Create();
                var officeTableCode = x.InsertWithNewId(new TableCode {TableTypeId = (int) TableTypes.Office, Name = Fixture.String(5)});
                var office = x.InsertWithNewId(new Office(officeTableCode.Id, officeTableCode.Name) {Organisation = nonEntityOrg});
                @case.Office = office;
                var rowSecurityUsesCaseOffice = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.RowSecurityUsesCaseOffice);
                rowSecurityUsesCaseOffice.BooleanValue = forFailure;
                if (canDefaultFromCaseOfficeEntity)
                {
                    var entityDefaultsFromCaseOffice = x.DbContext.Set<SiteControl>().SingleOrDefault(_ => _.ControlId == SiteControls.EntityDefaultsFromCaseOffice);
                    if (entityDefaultsFromCaseOffice != null)
                        entityDefaultsFromCaseOffice.BooleanValue = forFailure;
                }

                x.DbContext.SaveChanges();
            });
        }

        public static void CreateWorkHistoryFor(int caseId, int entityNo, int employeeNo, decimal? amountUsed, decimal? billed, decimal? unbilled)
        {
            DbSetup.Do(x =>
            {
                var today = DateTime.Now.Date;
                var tomorrow = today.AddDays(1);
                var postPeriod = x.DbContext.Set<Period>().Where(_ => _.EndDate > tomorrow).OrderBy(_ => _.Id).Select(_ => _.Id).FirstOrDefault();
                x.Insert(new TransactionHeader
                {
                    StaffId = employeeNo,
                    EntityId = entityNo,
                    TransactionId = 1,
                    EntryDate = today,
                    TransactionDate = today,
                    UserLoginId = Fixture.String(10),
                    PostPeriodId = postPeriod
                });
                x.Insert(new WorkHistory
                {
                    CaseId = caseId,
                    Status = TransactionStatus.Active,
                    MovementClass = MovementClass.Entered,
                    LocalValue = amountUsed,
                    EntityId = entityNo,
                    TransactionId = 1,
                    WipSequenceNo = 1,
                    HistoryLineNo = 1,
                    TransDate = today.AddDays(-1),
                    PostPeriodId = postPeriod
                });
                x.Insert(new TransactionHeader
                {
                    StaffId = employeeNo,
                    EntityId = entityNo,
                    TransactionId = 2,
                    EntryDate = today,
                    TransactionDate = today,
                    UserLoginId = Fixture.String(10),
                    PostPeriodId = postPeriod
                });
                x.Insert(new WorkHistory
                {
                    CaseId = caseId,
                    Status = TransactionStatus.Active,
                    MovementClass = MovementClass.Billed,
                    LocalValue = -billed,
                    EntityId = entityNo,
                    TransactionId = 2,
                    WipSequenceNo = 1,
                    HistoryLineNo = 1,
                    TransDate = today.AddDays(-1),
                    PostPeriodId = postPeriod
                });
                x.Insert(new WorkInProgress
                {
                    CaseId = caseId,
                    Status = TransactionStatus.Active,
                    Balance = unbilled,
                    EntityId = entityNo,
                    TransactionId = 1,
                    TransactionDate = DateTime.Now.Date.AddDays(-1)
                });
                x.Insert(new WorkInProgress
                {
                    CaseId = caseId,
                    Status = TransactionStatus.Active,
                    Balance = 500,
                    EntityId = entityNo,
                    TransactionId = 2,
                    WipSequenceNo = 2,
                    TransactionDate = new DateTime(2014, 1, 1)
                });
            });
        }

        public static void SetupPeriod(bool withWarning = false)
        {
            DbSetup.Do(db =>
            {
                var today = DateTime.Today;
                var currentPeriod = db.DbContext.Set<Period>().SingleOrDefault(_ => _.StartDate <= today && _.EndDate >= today);
                if (currentPeriod == null) return;
                if (withWarning)
                {
                    currentPeriod.ClosedForModules = SystemIdentifier.TimeAndBilling;
                }

                currentPeriod.PostingCommenced = currentPeriod.StartDate.AddDays(-1);
                db.DbContext.SaveChanges();
            });
        }

        public static void Cleanup()
        {
            SiteControlRestore.ToDefault(
                                         SiteControls.CURRENCY, 
                                         SiteControls.EntityDefaultsFromCaseOffice, 
                                         SiteControls.RowSecurityUsesCaseOffice, 
                                         SiteControls.WIPSplitMultiDebtor);
            
            DbSetup.Do(db =>
            {
                var today = DateTime.Today;
                var currentPeriod = db.DbContext.Set<Period>().SingleOrDefault(_ => _.StartDate <= today && _.EndDate >= today);
                if (currentPeriod == null) return;
                currentPeriod.ClosedForModules = null;
                currentPeriod.PostingCommenced = null;

                db.DbContext.SaveChanges();
            });
        }
    }
}