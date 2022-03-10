using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Account;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.Cost;
using InprotechKaizen.Model.Accounting.Debtor;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Integration.DbHelpers
{
    internal static class TimeRecordingDbHelper
    {
        public static bool CheckValues(int entryNo, string activityId = null)
        {
            Diary entry = null;
            DbSetup.Do(x =>
            {
                entry = x.DbContext.Set<Diary>().FirstOrDefault(_ => _.EntryNo == entryNo); 
            });

            if (entry == null)
                return false;

            return string.IsNullOrEmpty(activityId) || entry.Activity == activityId;
        }

        public static Diary StartTimer(int staffNameId, int caseId)
        {
            Diary timer = null;
            var today = DateTime.Now.Date;
            DbSetup.Do(x =>
            {
                var entryNo = x.DbContext.Set<Diary>().Select(_ => _.EntryNo).DefaultIfEmpty(0).Max() + 1;
                timer = new DiaryBuilder(x.DbContext).Create(staffNameId, entryNo, today, caseId, null, null, Fixture.String(100), Fixture.String(10), null, 0, 0, 0);
                timer.IsTimer = 1;

                x.DbContext.SaveChanges();
            });

            return timer;
        }

        public static TimeRecordingData SetupCreditLimit(TimeRecordingData input)
        {
            DbSetup.Do(x =>
            {
                var today = DateTime.Now.Date;
                var tomorrow = today.AddDays(1);
                var postPeriod = x.DbContext.Set<Period>().Where(_ => _.EndDate > tomorrow).OrderBy(_ => _.Id).Select(_ => _.Id).FirstOrDefault();

                CreateReceivable(x, input.EntityId, input.Debtor, input.StaffName, today, postPeriod);
                CreateReceivable(x, input.EntityId, input.Debtor2, input.StaffName, today, postPeriod);
                var limit = x.DbContext.Set<SiteControl>()
                             .Single(_ => _.ControlId == SiteControls.CreditLimitWarningPercentage);
                limit.IntegerValue = 50;
                x.DbContext.SaveChanges();

                input.CreditLimit = new
                {
                    value = 2000,
                    balance = 2000,
                    limitPercentage = 50
                };
            });

            void CreateReceivable(DbSetup dbSetup, int i, Name name, Name staffName1, DateTime dateTime, int postPeriod1)
            {
                dbSetup.Insert(new Account { EntityId = i, NameId = name.Id, Balance = (decimal?)2.0, CreditBalance = (decimal?)2.0 });
                var transNo = Fixture.Integer();
                dbSetup.Insert(new TransactionHeader
                {
                    StaffId = staffName1.Id,
                    EntityId = i,
                    TransactionId = transNo,
                    EntryDate = dateTime,
                    TransactionDate = dateTime,
                    UserLoginId = Fixture.String(10),
                    PostPeriodId = postPeriod1
                });
                dbSetup.Insert(new OpenItem
                {
                    AccountEntityId = i,
                    AccountDebtorId = name.Id,
                    ItemTransactionId = transNo,
                    ItemEntityId = i,
                    OpenItemNo = Fixture.AlphaNumericString(5),
                    LocalValue = 1000,
                    LocalBalance = 1000,
                    Status = TransactionStatus.Active,
                    TypeId = ItemType.DebitNote,
                    ClosePostDate = dateTime.AddDays(10),
                    ItemDate = dateTime.AddMonths(-1)
                });
                dbSetup.Insert(new TransactionHeader
                {
                    StaffId = staffName1.Id,
                    EntityId = i,
                    TransactionId = transNo + 1,
                    EntryDate = dateTime,
                    TransactionDate = dateTime,
                    UserLoginId = Fixture.String(10),
                    PostPeriodId = postPeriod1
                });
                dbSetup.Insert(new OpenItem
                {
                    AccountEntityId = i,
                    AccountDebtorId = name.Id,
                    ItemTransactionId = transNo + 1,
                    ItemEntityId = i,
                    OpenItemNo = Fixture.AlphaNumericString(5),
                    LocalValue = 1000,
                    LocalBalance = 1000,
                    Status = TransactionStatus.Active,
                    TypeId = ItemType.DebitNote,
                    ClosePostDate = dateTime.AddDays(10),
                    ItemDate = dateTime.AddMonths(-1)
                });
            }

            return input;
        }

        public static int GetDiaryCount(int nameId)
        {
            return DbSetup.Do(db => db.DbContext.Set<Diary>().Count(_ => _.EmployeeNo == nameId));
        }

        public static void SetAccessForEditPostedTask(TestUser user, Allow allow = Allow.Modify)
        {
            var u = new Users();
            DbSetup.Do(db =>
            {
                u.Name = db.DbContext.Set<Name>().SingleOrDefault(_ => _.Id == user.NameId);
                u.WithPermission(ApplicationTask.MaintainPostedTime, allow);
            });
        }

        public static void EnableUnitsAdjustmentForContinuedEntries(bool value)
        {
            DbSetup.Do(x =>
            {
                var adjustUnitsOnContinuedEntries = x.DbContext.Set<SiteControl>()
                                                     .Single(_ => _.ControlId == SiteControls.ContEntryUnitsAdjmt);
                adjustUnitsOnContinuedEntries.BooleanValue = value;
                x.DbContext.SaveChanges();
            });
        }

        public static TimeRecordingData SetupBillingCap(TimeRecordingData input)
        {
            DbSetup.Do(x =>
            {
                var staffName = input.StaffName;
                var entityId = input.EntityId;
                var debtor = input.Debtor;
                var @case = input.Case;
                var clientDetail = debtor.ClientDetail;

                var transNo = Fixture.Integer();
                var today = DateTime.Now.Date;
                var tomorrow = today.AddDays(1);
                var postPeriod = x.DbContext.Set<Period>().Where(_ => _.EndDate > tomorrow).OrderBy(_ => _.Id).Select(_ => _.Id).FirstOrDefault();
                x.Insert(new TransactionHeader
                {
                    StaffId = staffName.Id,
                    EntityId = entityId,
                    TransactionId = transNo,
                    EntryDate = today,
                    TransactionDate = today,
                    UserLoginId = Fixture.String(10),
                    PostPeriodId = postPeriod
                });
                x.Insert(new Account {EntityId = entityId, NameId = debtor.Id, Balance = (decimal?) 2.0, CreditBalance = (decimal?) 2.0});
                x.Insert(new OpenItem
                {
                    AccountEntityId = entityId,
                    AccountDebtorId = debtor.Id,
                    ItemTransactionId = transNo,
                    ItemEntityId = entityId,
                    OpenItemNo = Fixture.AlphaNumericString(5),
                    LocalValue = 1000,
                    Status = TransactionStatus.Active,
                    TypeId = ItemType.DebitNote,
                    PostDate = today
                });
                x.Insert(new OpenItemCase
                {
                    CaseId = @case.Id,
                    AccountDebtorId = debtor.Id,
                    ItemEntityId = entityId,
                    AccountEntityId = entityId,
                    ItemTransactionId = transNo,
                    LocalValue = 1000,
                    Status = TransactionStatus.Active
                });
                var debtorTransNo = transNo + 1;
                x.Insert(new TransactionHeader
                {
                    StaffId = staffName.Id,
                    EntityId = entityId,
                    TransactionId = debtorTransNo,
                    EntryDate = today,
                    TransactionDate = today,
                    UserLoginId = Fixture.String(10),
                    PostPeriodId = postPeriod
                });
                x.Insert(new OpenItem
                {
                    AccountEntityId = entityId,
                    AccountDebtorId = debtor.Id,
                    ItemTransactionId = debtorTransNo,
                    ItemEntityId = entityId,
                    OpenItemNo = Fixture.AlphaNumericString(5),
                    LocalValue = 1100,
                    Status = TransactionStatus.Active,
                    TypeId = ItemType.DebitNote,
                    PostDate = today
                });

                x.DbContext.SaveChanges();

                input.BillingCap = new
                {
                    value = 1000,
                    startDate = clientDetail.BillingCapStartDate,
                    totalBilled = 2100,
                    period = $"{clientDetail.BillingCapPeriod} month(s)"
                };
            });

            return input;
        }

        public static TimeRecordingData SetupLastInvoicedDate(TimeRecordingData input)
        {
            var staffName = input.StaffName;
            var entityId = input.EntityId;
            var debtor = input.Debtor;
            var @case = input.Case;

            var transNo = Fixture.Integer();
            var lastInvoiceDate = new DateTime(2010, 10, 11);
            DbSetup.Do(x =>
            {
                var today = DateTime.Now.Date;
                var tomorrow = today.AddDays(1);
                var postPeriod = x.DbContext.Set<Period>().Where(_ => _.EndDate > tomorrow).OrderBy(_ => _.Id).Select(_ => _.Id).FirstOrDefault();
                x.Insert(new TransactionHeader
                {
                    StaffId = staffName.Id,
                    EntityId = entityId,
                    TransactionId = transNo,
                    EntryDate = today,
                    TransactionDate = today,
                    UserLoginId = Fixture.String(10),
                    PostPeriodId = postPeriod
                });
                x.Insert(new Account {EntityId = entityId, NameId = debtor.Id, Balance = (decimal?) 2.0, CreditBalance = (decimal?) 2.0});
                x.Insert(new OpenItem
                {
                    AccountEntityId = entityId,
                    AccountDebtorId = debtor.Id,
                    ItemTransactionId = transNo,
                    ItemEntityId = entityId,
                    OpenItemNo = Fixture.AlphaNumericString(5),
                    LocalValue = 1000,
                    Status = TransactionStatus.Active,
                    TypeId = ItemType.DebitNote,
                    PostDate = today,
                    ItemDate = lastInvoiceDate,
                    BillPercentage = 100
                });
                x.Insert(new WorkHistory
                {
                    RefTransactionId = transNo,
                    RefEntityId = entityId,
                    CaseId = @case.Id,
                    Status = TransactionStatus.Active,
                    MovementClass = MovementClass.Billed,
                    LocalValue = 10,
                    EntityId = entityId,
                    TransactionId = 1,
                    WipSequenceNo = 3,
                    HistoryLineNo = 2,
                    TransDate = today.AddDays(-1),
                    PostDate = today.AddDays(-1),
                    PostPeriodId = postPeriod,
                    BillLineNo = 1,
                    WipCode = "E2EWIP"
                });
                x.Insert(new DebtorHistory
                {
                    AccountEntityId = entityId,
                    AccountDebtorId = debtor.Id,
                    ItemEntityId = entityId,
                    LocalValue = 1000,
                    LocalBalance = 1000,
                    HistoryLineNo = 1,
                    RefTransactionId = transNo,
                    RefEntityId = entityId,
                    ItemTransactionId = transNo,
                    MovementClass = MovementClass.Entered
                });
                x.Insert(new BillLine
                {
                    ItemEntityId = entityId,
                    ItemTransactionId = transNo,
                    ItemLineNo = 1
                });
                input.LastInvoiceDate = lastInvoiceDate;
                input.CurrentPeriod = postPeriod;
            });

            return input;
        }

        public static TimeRecordingData SetupPrepayments(TimeRecordingData input)
        {
            DbSetup.Do(x =>
            {
                var staffName = input.StaffName;
                var entityId = input.EntityId;
                var debtor = input.Debtor;
                var @case = input.Case;
                var activity = input.NewActivity;

                var enablePrepaymentWarning = x.DbContext.Set<SiteControl>()
                                               .Single(_ => _.ControlId == SiteControls.PrepaymentWarnOver);
                enablePrepaymentWarning.BooleanValue = true;
                var transNo = Fixture.Integer();
                var today = DateTime.Now.Date;
                var tomorrow = today.AddDays(1);
                var postPeriod = x.DbContext.Set<Period>().Where(_ => _.EndDate > tomorrow).OrderBy(_ => _.Id).Select(_ => _.Id).FirstOrDefault();
                x.Insert(new TransactionHeader
                {
                    StaffId = staffName.Id,
                    EntityId = entityId,
                    TransactionId = transNo,
                    EntryDate = today,
                    TransactionDate = today,
                    UserLoginId = Fixture.String(10),
                    PostPeriodId = postPeriod
                });
                x.Insert(new Account {EntityId = entityId, NameId = debtor.Id, Balance = (decimal?) 2.0, CreditBalance = (decimal?) 2.0});
                x.Insert(new OpenItem
                {
                    AccountEntityId = entityId,
                    AccountDebtorId = debtor.Id,
                    ItemTransactionId = transNo,
                    ItemEntityId = entityId,
                    OpenItemNo = "555PP",
                    LocalValue = 100,
                    LocalBalance = 100,
                    PreTaxValue = -100,
                    Status = TransactionStatus.Active,
                    TypeId = ItemType.Prepayment,
                });
                x.Insert(new OpenItemCase
                {
                    CaseId = @case.Id,
                    AccountDebtorId = debtor.Id,
                    ItemEntityId = entityId,
                    AccountEntityId = entityId,
                    ItemTransactionId = transNo,
                    LocalValue = 100,
                    LocalBalance = 100,
                    Status = TransactionStatus.Active
                });
                var debtorTransNo = transNo + 1;
                x.Insert(new TransactionHeader
                {
                    StaffId = staffName.Id,
                    EntityId = entityId,
                    TransactionId = debtorTransNo,
                    EntryDate = today,
                    TransactionDate = today,
                    UserLoginId = Fixture.String(10),
                    PostPeriodId = postPeriod
                });
                x.Insert(new OpenItem
                {
                    AccountEntityId = entityId,
                    AccountDebtorId = debtor.Id,
                    ItemTransactionId = debtorTransNo,
                    ItemEntityId = entityId,
                    OpenItemNo = "556PP",
                    LocalValue = 100,
                    LocalBalance = 100,
                    PreTaxValue = -100,
                    Status = TransactionStatus.Active,
                    TypeId = ItemType.Prepayment
                });
                new WipBuilder(x.DbContext).BuildDebtorOnlyWip(entityId, debtor.Id, activity.WipCode, 200);

                x.DbContext.SaveChanges();
            });

            input.Prepayments = new
            {
                casePrepayment = 100,
                debtorPrepayment = 100
            };

            return input;
        }

        public static TimeRecordingData Setup(bool withStartTime = false,
                                              bool withValueOnEntryPreference = false,
                                              bool withEntriesToday = true,
                                              bool showSecondsPreference = false,
                                              bool allowWipView = true,
                                              bool allowBillHistory = true,
                                              bool allowReceivables = true,
                                              bool withHoursOnlyTime = false,
                                              bool withMultiDebtorEnabled = false,
                                              bool isDebtorNameTypeRestricted = true)
        {
            TimeRecordingData dbData = null;

            DbSetup.Do(x =>
            {
                var today = DateTime.Now.Date;
                var staffName = new NameBuilder(x.DbContext).CreateStaff();
                var userSetup = new Users(x.DbContext) {Name = staffName}.WithPermission(ApplicationTask.MaintainTimeViaTimeRecording)
                                                                         .WithPermission(ApplicationTask.ShowLinkstoWeb)
                                                                         .WithPermission(ApplicationTask.MaintainCaseBillNarrative);
                if (!allowWipView)
                    userSetup.WithSubjectPermission(ApplicationSubject.WorkInProgressItems, SubjectDeny.Select);

                if (!allowBillHistory)
                    userSetup.WithSubjectPermission(ApplicationSubject.BillingHistory, SubjectDeny.Select);

                if (!allowReceivables)
                    userSetup.WithSubjectPermission(ApplicationSubject.ReceivableItems, SubjectDeny.Select);

                var user = userSetup.Create();

                var activity = new WipTemplateBuilder(x.DbContext).Create("E2E");
                var newActivity = new WipTemplateBuilder(x.DbContext).Create("NEW");
                var continuedActivity = new WipTemplateBuilder(x.DbContext).Create("CONTINUED");

                var currency = new CurrencyBuilder(x.DbContext).Create();

                var homeCurrency = new CurrencyBuilder(x.DbContext).Create();
                var localCurrency = x.DbContext.Set<SiteControl>()
                                     .Single(_ => _.ControlId == SiteControls.CURRENCY);
                localCurrency.StringValue = homeCurrency.Id;
                var newTimeEntriesEmpty = x.DbContext.Set<SiteControl>()
                                           .Single(_ => _.ControlId == SiteControls.TimeEmptyForNewEntries);
                newTimeEntriesEmpty.BooleanValue = !withStartTime;
                var splitMultiDebtorWip = x.DbContext.Set<SiteControl>()
                                           .Single(_ => _.ControlId == SiteControls.WIPSplitMultiDebtor);
                splitMultiDebtorWip.BooleanValue = withMultiDebtorEnabled;
                x.DbContext.SaveChanges();

                var u = x.DbContext.Set<User>().Single(_ => _.Id == user.Id);
                x.Insert(new SettingValues
                {
                    BooleanValue = false,
                    User = u,
                    SettingId = KnownSettingIds.HideContinuedEntries
                });

                var entityName = new NameBuilder(x.DbContext).Create("E2E-Entity");
                x.Insert(new SpecialName(true, entityName));

                var debtorNameType = x.DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Debtor);
                debtorNameType.IsNameRestricted = isDebtorNameTypeRestricted ? 1 : 0;

                var debtor1 = new NameBuilder(x.DbContext).CreateClientOrg("E2E");
                var debtorWithRestriction = debtor1.Id.ToString();
                var clientDetail = x.Insert(new ClientDetail(debtor1.Id)
                {
                    BillingCap = 1000,
                    BillingCapStartDate = DateTime.Now.Date.AddMonths(-1),
                    BillingCapPeriod = 3,
                    BillingCapPeriodType = KnownPeriodTypes.Months,
                    IsBillingCapRecurring = true,
                    CreditLimit = 2000
                });
                clientDetail.DebtorStatus = x.InsertWithNewId(new DebtorStatus(KnownDebtorRestrictions.DisplayError)
                {
                    RestrictionType = KnownDebtorRestrictions.DisplayError,
                    Status = Fixture.String(20)
                });
                var debtor2 = new NameBuilder(x.DbContext).CreateClientOrg("E2E2");
                var debtorWithoutRestriction = debtor2.Id.ToString();
                x.Insert(new ClientDetail(debtor2.Id) { CreditLimit = 2000 });

                var @case = new CaseBuilder(x.DbContext).Create("e2e", null, user.Username, null, null, false);
                var budget = new
                {
                    budgetAmount = 2000,
                    budgetRevised = 3000,
                    budgetStartDate = new DateTime(2015, 1, 1),
                    budgetEndDate = DateTime.Now.Date.AddDays(7),
                    amountUsed = 6000,
                    currency = currency.Id,
                    usedPerc = 200,
                    billed = 100,
                    unbilled = 10
                };
                @case.BudgetAmount = budget.budgetAmount;
                @case.BudgetRevisedAmt = budget.budgetRevised;
                @case.BudgetStartDate = budget.budgetStartDate;
                @case.BudgetEndDate = budget.budgetEndDate;
                AccountingDbHelper.CreateWorkHistoryFor(@case.Id, entityName.Id, staffName.Id, budget.amountUsed, budget.billed, budget.unbilled - 10);

                new OpenActionBuilder(x.DbContext).CreateInDb(@case);

                @case.CaseNames.Add(new CaseName(@case, debtorNameType, debtor1, 100) {BillingPercentage = RestrictedDebtorBillPercentage});
                @case.CaseNames.Add(new CaseName(@case, debtorNameType, debtor2, 101) {BillingPercentage = UnrestrictedDebtorBillPercentage});

                var newCase = new CaseBuilder(x.DbContext).Create("e2e-new", null, user.Username, null, null, false);
                newCase.CaseNames.Add(new CaseName(newCase, debtorNameType, debtor1, 100) {BillingPercentage = RestrictedDebtorBillPercentage});

                var case2 = new CaseBuilder(x.DbContext).Create("e2e2", true);

                var narrative = new NarrativeBuilder(x.DbContext).Create("e2e");
                x.DbContext.SaveChanges();

                var narrativeForContinuedEntries = "long-narrative" + Fixture.String(200);
                var notesForContinuedEntries = "note3" + Fixture.String(249);

                case2.CaseStatus = x.DbContext.Set<Status>().FirstOrDefault(_ => _.Id == -291);

                new NameBuilder(x.DbContext).CreateClientIndividual("E2E");

                if (withEntriesToday)
                {
                    new DiaryBuilder(x.DbContext).Create(staffName.Id, 10, today.AddHours(12).AddMinutes(30), @case.Id, null, activity.WipCode, "short-narrative" + Fixture.String(200), "note1" + Fixture.String(249), null, 300, 300, null);
                    var parentEntry = new DiaryBuilder(x.DbContext).Create(staffName.Id, 1, today.AddHours(12), @case.Id, null, continuedActivity.WipCode, narrativeForContinuedEntries, notesForContinuedEntries, currency.Id, 300, 300, 30, parentEntryNo: 3);
                    parentEntry.TotalUnits = 20;
                    new DiaryBuilder(x.DbContext).Create(staffName.Id, 2, today.AddHours(11), null, debtor1.Id, activity.WipCode, "short-narrative" + Fixture.String(254), "note2" + Fixture.String(249), null, 400, 400, 30);
                    new DiaryBuilder(x.DbContext).Create(staffName.Id, 3, today.AddHours(10), @case.Id, null, continuedActivity.WipCode, narrativeForContinuedEntries, notesForContinuedEntries, null, null, null, null, isContinuedParent: true);
                    new DiaryBuilder(x.DbContext).Create(staffName.Id, 4, today.AddHours(9), @case.Id, null, activity.WipCode, Fixture.String(100), "posted" + Fixture.String(10), currency.Id, 300, 300, 30, true);
                    new DiaryBuilder(x.DbContext).Create(staffName.Id, 5, today.AddHours(8), null, null, activity.WipCode, Fixture.String(100), "incomplete" + Fixture.String(10), currency.Id, 300, 300, 30);
                    var lastIncompleteEntry = new DiaryBuilder(x.DbContext).Create(staffName.Id, 9, today.AddHours(7), null, null, activity.WipCode, Fixture.String(100), "incomplete" + Fixture.String(10), currency.Id, 300, 300, 30);
                    lastIncompleteEntry.TotalTime = lastIncompleteEntry.TotalTime.GetValueOrDefault().AddHours(-1).AddSeconds(10);
                    lastIncompleteEntry.FinishTime = lastIncompleteEntry.StartTime.GetValueOrDefault().AddSeconds(10);
                    lastIncompleteEntry.TotalUnits = 0;
                }
                
                new DiaryBuilder(x.DbContext).Create(staffName.Id, 6, today.AddDays(-1), null, debtor1.Id, activity.WipCode, "yesterday" + Fixture.String(100), Fixture.String(10), currency.Id, 300, 300, 30);
                new DiaryBuilder(x.DbContext).Create(staffName.Id, 7, today.AddDays(1), null, debtor1.Id, activity.WipCode, "tomorrow" + Fixture.String(100), Fixture.String(10), currency.Id, 0, 0, 0);
                new DiaryBuilder(x.DbContext).Create(staffName.Id, 8, today.AddDays(-2), case2.Id, null, activity.WipCode, Fixture.String(100), Fixture.String(10), currency.Id, 0, 0, 0);
                new WipBuilder(x.DbContext).Build(entityName.Id, @case.Id, activity.WipCode, 10);
                new WipBuilder(x.DbContext).Build(entityName.Id, case2.Id, activity.WipCode, 90);

                if (withHoursOnlyTime)
                {
                    new DiaryBuilder(x.DbContext).Create(staffName.Id, 11, today.Date, @case.Id, null, activity.WipCode, "hours-only" + Fixture.String(200), "hours-only", null, 300, 300, null, isHoursOnly: true);
                }

                var homeName = (from s in x.DbContext.Set<SiteControl>()
                                join n in x.DbContext.Set<Name>() on s.IntegerValue equals n.Id
                                where s.ControlId == SiteControls.HomeNameNo
                                select n).FirstOrDefault();

                if (withValueOnEntryPreference)
                {
                    x.InsertWithNewId(new SettingValues {BooleanValue = true, SettingId = KnownSettingIds.ValueTimeOnEntry, User = x.DbContext.Set<User>().Single(_ => _.Id == user.Id)});
                }

                if (showSecondsPreference)
                {
                    x.InsertWithNewId(new SettingValues {BooleanValue = true, SettingId = KnownSettingIds.DisplayTimeWithSeconds, User = x.DbContext.Set<User>().Single(_ => _.Id == user.Id)});
                }

                if (withMultiDebtorEnabled)
                {
                    x.InsertWithNewId(new TimeCosting {ChargeUnitRate = 100, NameNo = debtor2.Id, EffectiveDate = new DateTime(1999, 1, 1)});
                }

                var freeActivity = new WipTemplateBuilder(x.DbContext).Create("FREE");
                x.InsertWithNewId(new TimeCosting {ChargeUnitRate = 0, ActivityKey = freeActivity.WipCode, EffectiveDate = new DateTime(1999, 1, 1)});

                dbData = new TimeRecordingData
                {
                    StaffName = staffName,
                    User = user,
                    Currency = currency,
                    DebtorWithRestriction = debtorWithRestriction,
                    DebtorWithoutRestriction = debtorWithoutRestriction,
                    Case = @case,
                    Case2 = case2,
                    NewCaseSameDebtor = newCase,
                    Narrative = narrative,
                    HomeCurrency = homeCurrency,
                    NewActivity = newActivity,
                    HomeName = homeName?.LastName,
                    EntityName = entityName.LastName,
                    Budget = budget,
                    ContinuedActivity = continuedActivity,
                    Debtor = debtor1,
                    Debtor2 = debtor2,
                    EntityId = entityName.Id
                };
            });

            return dbData;
        }

        public static string SetupFunctionSecurity(FunctionSecurityPrivilege[] requiredPrivileges, int staffId)
        {
            Name staff1 = null;
            DbSetup.Do(x =>
            {
                var allAccess = x.DbContext.Set<FunctionSecurity>().Where(_ => _.AccessStaffId == null && _.OwnerId == null && _.FunctionTypeId == (short) BusinessFunction.TimeRecording && _.SequenceNo == 1 && _.AccessPrivileges == 287);
                if (allAccess.Any())
                {
                    foreach (var functionSecurity in allAccess)
                        functionSecurity.OwnerId = -487;
                }

                staff1 = new NameBuilder(x.DbContext).CreateStaff("Func");
                new NameBuilder(x.DbContext).CreateStaff("NoFunc");
                new FunctionSecurityBuilder(x.DbContext).Build(BusinessFunction.TimeRecording, requiredPrivileges, staffId, staff1.Id, null);

                var today = DateTime.Now.Date;
                new DiaryBuilder(x.DbContext).Create(staff1.Id,
                                                     8,
                                                     today.AddHours(10).AddMinutes(30),
                                                     null,
                                                     null,
                                                     null,
                                                     "e2e-func" + Fixture.String(100),
                                                     "e2e-func" + Fixture.String(100),
                                                     null,
                                                     Fixture.Short(500),
                                                     Fixture.Short(10),
                                                     0);

                x.DbContext.SaveChanges();
            });

            return staff1?.FormattedWithDefaultStyle();
        }

        public static void Cleanup()
        {
            SiteControlRestore.ToDefault(SiteControls.CURRENCY, SiteControls.EntityDefaultsFromCaseOffice, SiteControls.RowSecurityUsesCaseOffice, SiteControls.ContEntryUnitsAdjmt, SiteControls.PrepaymentWarnOver, SiteControls.WIPSplitMultiDebtor);

            AccountingDbHelper.Cleanup();

            DbSetup.Do(db =>
            {
                var allAccess = db.DbContext.Set<FunctionSecurity>().Where(_ => _.AccessStaffId == null && _.OwnerId == -487 && _.FunctionTypeId == (short) BusinessFunction.TimeRecording && _.SequenceNo == 1 && _.AccessPrivileges == 287);
                if (!allAccess.Any()) return;
                foreach (var functionSecurity in allAccess)
                    functionSecurity.OwnerId = null;

                db.DbContext.SaveChanges();
            });
        }

        public const int RestrictedDebtorBillPercentage = 40;
        public const int UnrestrictedDebtorBillPercentage = 60;
    }

    public class TimeRecordingData
    {
        public Name StaffName { get; set; }
        public TestUser User { get; set; }
        public Currency Currency { get; set; }
        public string DebtorWithRestriction { get; set; }
        public string DebtorWithoutRestriction { get; set; }
        public Case Case { get; set; }
        public Case Case2 { get; set; }
        public Case NewCaseSameDebtor { get; set; }
        public Narrative Narrative { get; set; }
        public Currency HomeCurrency { get; set; }
        public WipTemplate NewActivity { get; set; }
        public string HomeName { get; set; }
        public string EntityName { get; set; }
        public dynamic Budget { get; set; }
        public WipTemplate ContinuedActivity { get; set; }
        public Name Debtor { get; set; }
        public Name Debtor2 { get; set; }
        public dynamic Prepayments { get; set; }
        public int EntityId { get; set; }
        public dynamic BillingCap { get; set; }
        public dynamic CreditLimit { get; set; }
        public DateTime? LastInvoiceDate { get; set; }
        public int? CurrentPeriod { get; set; }
    }
}