using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.SplitWip
{
    public class SplitWipDbSetUp : DbSetup
    {
        const int DebtorBillPercentage40 = 40;
        public dynamic ForSplitWip()
        {
            AccountingDbHelper.SetupPeriod();

            return Do(x =>
            {
                var staffName = new NameBuilder(x.DbContext).CreateStaff();
                new Users(x.DbContext)
                {
                    Name = staffName
                }.WithPermission(ApplicationTask.AdjustWip)
                     .WithPermission(ApplicationTask.RecordWip, Allow.Create);

                var serviceChargeWipType = x.InsertWithNewAlphaNumericId(new WipType { CategoryId = "SC" });

                var serviceChargeWipTemplate1 = new WipTemplateBuilder(x.DbContext).Create("SC2", typeId: serviceChargeWipType.Id);

                var homeEntity = x.DbContext.Set<SiteControl>()
                                  .Single(_ => _.ControlId == SiteControls.HomeNameNo)
                                  .IntegerValue.GetValueOrDefault();

                var debtorNameType = x.DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Debtor);
                var foreignCurrency1 = new CurrencyBuilder(x.DbContext).Create("F1", (decimal)1.1, (decimal)1.1);
                var foreignDebtor1 = new NameBuilder(x.DbContext).CreateClientOrg("FOREIGN-1");
                x.Insert(new ClientDetail(foreignDebtor1.Id) { CurrencyId = foreignCurrency1.Id });

                var caseForeignMultiple = new CaseBuilder(x.DbContext).Create("foreign-multiple", true, withDebtor: false);
                caseForeignMultiple.CaseNames.Add(new CaseName(caseForeignMultiple, debtorNameType, foreignDebtor1, 101) { BillingPercentage = DebtorBillPercentage40 });

                new OpenActionBuilder(x.DbContext).CreateInDb(caseForeignMultiple);

                var foreignWip = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(homeEntity, caseForeignMultiple.Id, serviceChargeWipTemplate1.WipCode, 1000, foreignCurrency: foreignCurrency1.Id, exchangeRate: (decimal)1.5);

                x.DbContext.SaveChanges();

                return foreignWip.Wip;
            });
        }
    }
}
