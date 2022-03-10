using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Wip
{
    public class AvailableWipItemExtensionsFacts
    {
        readonly decimal _balance = Fixture.Decimal();
        readonly decimal _localBilled = Fixture.Decimal();
        readonly decimal _localVariation = Fixture.Decimal();
        readonly decimal _foreignBilled = Fixture.Decimal();
        readonly decimal _foreignBalance = Fixture.Decimal();
        readonly decimal _foreignVariation = Fixture.Decimal();
        readonly decimal _variableFeeAmount = Fixture.Decimal();

        AvailableWipItem Create()
        {
            return new AvailableWipItem
            {
                Balance = _balance,
                LocalBilled = _localBilled,
                LocalVariation = _localVariation,
                ForeignBilled = _foreignBilled,
                ForeignBalance = _foreignBalance,
                ForeignVariation = _foreignVariation,
                VariableFeeAmount = _variableFeeAmount
            };
        }

        [Fact]
        public void ShouldNotModifyIfItIsDiscount()
        {
            var item = Create();

            item.IsDiscount = true;

            var _ = item.ReverseSignsForCreditNote();

            Assert.Equal(_balance, item.Balance);
            Assert.Equal(_localVariation, item.LocalVariation);
            Assert.Equal(_localBilled, item.LocalBilled);
            Assert.Equal(_foreignBilled, item.ForeignBilled);
            Assert.Equal(_foreignBalance, item.ForeignBalance);
            Assert.Equal(_foreignVariation, item.ForeignVariation);
            Assert.Equal(_variableFeeAmount, item.VariableFeeAmount);
        }

        [Fact]
        public void ShouldNotModifyIfItIsCreditWip()
        {
            var item = Create();

            item.IsCreditWip = true;

            var _ = item.ReverseSignsForCreditNote();

            Assert.Equal(_balance, item.Balance);
            Assert.Equal(_localVariation, item.LocalVariation);
            Assert.Equal(_localBilled, item.LocalBilled);
            Assert.Equal(_foreignBilled, item.ForeignBilled);
            Assert.Equal(_foreignBalance, item.ForeignBalance);
            Assert.Equal(_foreignVariation, item.ForeignVariation);
            Assert.Equal(_variableFeeAmount, item.VariableFeeAmount);
        }

        [Fact]
        public void ShouldReverseSigns()
        {
            var item = Create();

            var _ = item.ReverseSignsForCreditNote();

            Assert.Equal(_balance * -1, item.Balance);
            Assert.Equal(_localVariation * -1, item.LocalVariation);
            Assert.Equal(_localBilled * -1, item.LocalBilled);
            Assert.Equal(_foreignBilled * -1, item.ForeignBilled);
            Assert.Equal(_foreignBalance * -1, item.ForeignBalance);
            Assert.Equal(_foreignVariation * -1, item.ForeignVariation);
            Assert.Equal(_variableFeeAmount * -1, item.VariableFeeAmount);
        }

        [Fact]
        public void ShouldRemainAsNull()
        {
            var item = new AvailableWipItem();

            var _ = item.ReverseSignsForCreditNote();

            Assert.Null(item.Balance);
            Assert.Null(item.LocalVariation);
            Assert.Null(item.LocalBilled);
            Assert.Null(item.ForeignBilled);
            Assert.Null(item.ForeignBalance);
            Assert.Null(item.ForeignVariation);
            Assert.Null(item.VariableFeeAmount);
        }
    }
}
