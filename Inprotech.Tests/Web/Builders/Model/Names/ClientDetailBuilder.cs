using System;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class ClientDetailBuilder : IBuilder<ClientDetail>
    {
        public int? NameNo { get; set; }
        public DebtorStatus DebtorStatus { get; set; }
        public decimal? CreditLimit { get; set; }
        public decimal? BillingCapValue { get; set; }
        public DateTime? BillingCapStartDate { get; set; }
        public int? BillingCapPeriod { get; set; }
        public string BillingCapPeriodType { get; set; }
        public bool BillingCapRecurring { get; set; }

        public ClientDetail Build()
        {
            var clientDetail = new ClientDetail(NameNo ?? Fixture.Integer())
            {
                DebtorStatus = DebtorStatus,
                CreditLimit = CreditLimit ?? Fixture.Integer(),
                BillingCap = BillingCapValue,
                BillingCapStartDate = BillingCapStartDate ?? Fixture.PastDate(),
                BillingCapPeriod = BillingCapPeriod,
                BillingCapPeriodType = BillingCapPeriodType,
                IsBillingCapRecurring = BillingCapRecurring
            };
            return clientDetail;
        }

        public ClientDetail BuildForName(Name name)
        {
            NameNo = name.Id;
            return Build();
        }
    }
    public static class ClientDetailBuilderExt
    {
        public static ClientDetailBuilder WithBillingCap(this ClientDetailBuilder builder, decimal? value, DateTime startDate, int period, string periodType, bool recurring = false)
        {
            builder.BillingCapValue = value;
            builder.BillingCapPeriod = period;
            builder.BillingCapPeriodType = periodType;
            builder.BillingCapStartDate = startDate;
            builder.BillingCapRecurring = recurring;
            return builder;
        }
    }
}