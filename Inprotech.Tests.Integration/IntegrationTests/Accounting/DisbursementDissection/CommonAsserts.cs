using System;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.DisbursementDissection
{
    public class CommonAsserts
    {
        static decimal? ReverseSignForCreditWip(decimal? value)
        {
            return value * -1;
        }

        internal static dynamic ReverseSignForCreditWip(dynamic disbursementWip)
        {
            disbursementWip.Amount = ReverseSignForCreditWip((decimal?) disbursementWip.Amount);
            disbursementWip.ForeignAmount = ReverseSignForCreditWip((decimal?) disbursementWip.ForeignAmount);

            disbursementWip.Margin = ReverseSignForCreditWip((decimal?) disbursementWip.Margin);
            disbursementWip.ForeignMargin = ReverseSignForCreditWip((decimal?) disbursementWip.ForeignMargin);

            disbursementWip.Discount = ReverseSignForCreditWip((decimal?) disbursementWip.Discount);
            disbursementWip.LocalDiscountForMargin = ReverseSignForCreditWip((decimal?) disbursementWip.LocalDiscountForMargin);

            disbursementWip.ForeignDiscount = ReverseSignForCreditWip((decimal?) disbursementWip.ForeignDiscount);
            disbursementWip.ForeignDiscountForMargin = ReverseSignForCreditWip((decimal?) disbursementWip.ForeignDiscountForMargin);

            disbursementWip.LocalCost1 = ReverseSignForCreditWip((decimal?) disbursementWip.LocalCost1);
            disbursementWip.LocalCost2 = ReverseSignForCreditWip((decimal?) disbursementWip.LocalCost2);

            return disbursementWip;
        }

        internal static void CheckDisbursementSavedCorrectly(dynamic disbursementWip, string foreignCurrency, DateTime beforeSaveTime, dynamic mainWip, dynamic discountWip, string message)
        {
            Assert.AreEqual((DateTime) disbursementWip.TransDate, mainWip.TransactionDate, message + " Should save transaction date");
            Assert.LessOrEqual(beforeSaveTime, mainWip.PostDate, message + " Should have post date greater than when it was submitted");
            Assert.AreEqual((string) disbursementWip.WipCode, mainWip.WipCode, message + " Should have the same WIP Code");
            Assert.AreEqual((int) disbursementWip.StaffKey, mainWip.StaffId, message + " Should have the same Staff Id");
            Assert.AreEqual((decimal?) disbursementWip.Amount, mainWip.LocalCost, message + " Should have the same Local Cost");
            Assert.AreEqual((decimal?) disbursementWip.Amount + ((decimal?) disbursementWip.Margin ?? 0), mainWip.LocalValue, message + $" Should have the same Local Value based on sum of Local Cost ({(decimal?) disbursementWip.Amount}) and Margin ({(decimal?) disbursementWip.Margin})");
            Assert.AreEqual((int?) disbursementWip.NarrativeKey, mainWip.NarrativeId, message + " Should have the same Narrative Id");
            Assert.AreEqual((string) disbursementWip.DebitNoteText, mainWip.ShortNarrative, message + " Should have the same Narrative");
            Assert.AreEqual(foreignCurrency, mainWip.ForeignCurrency, message + " Should use specified foreign currency code");
            Assert.AreEqual((decimal?) disbursementWip.ForeignAmount, mainWip.ForeignCost, message + "Should have the same Foreign Cost");
            Assert.AreEqual((decimal?) disbursementWip.LocalCost1, mainWip.CostCalculation1, message + " Should have the same Cost Calculation 1");
            Assert.AreEqual((decimal?) disbursementWip.LocalCost2, mainWip.CostCalculation2, message + " Should have the same Cost Calculation 2");
            Assert.AreEqual((int?) disbursementWip.MarginNo, mainWip.MarginId, message + " Should have the same Margin No");

            if (discountWip != null)
            {
                Assert.AreEqual((DateTime) disbursementWip.TransDate, discountWip.TransactionDate, message + " Should save transaction date");
                Assert.LessOrEqual(beforeSaveTime, discountWip.PostDate, message + " Should have post date greater than when it was submitted");
                Assert.AreEqual((int) disbursementWip.StaffKey, discountWip.StaffId, message + " Should have the same Staff Id");
                Assert.AreEqual((decimal?) disbursementWip.Discount * -1, (decimal?) discountWip.LocalValue, message + " Should have the same discount value");
            }

            if (!string.IsNullOrWhiteSpace(foreignCurrency))
            {
                Assert.AreEqual((decimal?) disbursementWip.ForeignAmount, mainWip.PreMarginAmount, message + " Should have the same pre margin amount");
                Assert.AreEqual((decimal?) disbursementWip.ForeignAmount + ((decimal?) disbursementWip.ForeignMargin ?? 0), mainWip.ForeignValue, message + $" Should have the same Foreign Value based on sum of Foreign Cost ({(decimal?) disbursementWip.ForeignAmount}) and Margin ({(decimal?) disbursementWip.ForeignMargin})");

                if (discountWip != null)
                {
                    Assert.AreEqual(((decimal?) disbursementWip.ForeignDiscount - ((decimal?) disbursementWip.ForeignDiscountForMargin ?? 0)) * -1, (decimal?) discountWip.PreMarginAmount, message + $" Should have the same pre margin amount Discount ({(decimal?) disbursementWip.ForeignDiscount}) - (Foreign Discount For Margin ({(decimal?) disbursementWip.ForeignDiscountForMargin})");
                }
            }
            else
            {
                Assert.AreEqual((decimal?) disbursementWip.Amount, mainWip.PreMarginAmount, message + " Should have the same pre margin amount");
                Assert.AreEqual((decimal?) disbursementWip.Amount + ((decimal?) disbursementWip.Margin ?? 0), mainWip.LocalValue, message + $" Should have the same Local Value based on sum of Local Cost ({(decimal?) disbursementWip.Amount}) and Margin ({(decimal?) disbursementWip.Margin})");

                if (discountWip != null)
                {
                    Assert.AreEqual(((decimal?) disbursementWip.Discount - ((decimal?) disbursementWip.LocalDiscountForMargin ?? 0)) * -1, discountWip.PreMarginAmount, message + $" Should have the same pre margin amount Discount ({(decimal?) disbursementWip.Discount}) - (Local Discount For Margin ({(decimal?) disbursementWip.LocalDiscountForMargin}))");
                }
            }
        }

        internal static void CheckCreditWipDisbursementSavedCorrectly(dynamic disbursementWip, string foreignCurrency, DateTime beforeSaveTime, dynamic mainWip, dynamic discountWip, string message)
        {
            Assert.AreEqual((DateTime) disbursementWip.TransDate, mainWip.TransactionDate, message + " Should save transaction date");
            Assert.LessOrEqual(beforeSaveTime, mainWip.PostDate, message + " Should have post date greater than when it was submitted");
            Assert.AreEqual((string) disbursementWip.WipCode, mainWip.WipCode, message + " Should have the same WIP Code");
            Assert.AreEqual((int) disbursementWip.StaffKey, mainWip.StaffId, message + " Should have the same Staff Id");
            Assert.AreEqual(ReverseSignForCreditWip((decimal?) disbursementWip.Amount), mainWip.LocalCost, message + " Should have the same Local Cost");
            Assert.AreEqual(ReverseSignForCreditWip((decimal?) disbursementWip.Amount + ((decimal?) disbursementWip.Margin ?? 0)), mainWip.LocalValue, message + $" Should have the same Local Value based on sum of Local Cost ({(decimal?) disbursementWip.Amount}) and Margin ({(decimal?) disbursementWip.Margin})");
            Assert.AreEqual((int?) disbursementWip.NarrativeKey, mainWip.NarrativeId, message + " Should have the same Narrative Id");
            Assert.AreEqual((string) disbursementWip.DebitNoteText, mainWip.ShortNarrative, message + " Should have the same Narrative");
            Assert.AreEqual(foreignCurrency, mainWip.ForeignCurrency, message + " Should use specified foreign currency code");
            Assert.AreEqual(ReverseSignForCreditWip((decimal?) disbursementWip.ForeignAmount), mainWip.ForeignCost, message + "Should have the same Foreign Cost");
            Assert.AreEqual(ReverseSignForCreditWip((decimal?) disbursementWip.LocalCost1), mainWip.CostCalculation1, message + " Should have the same Cost Calculation 1");
            Assert.AreEqual(ReverseSignForCreditWip((decimal?) disbursementWip.LocalCost2), mainWip.CostCalculation2, message + " Should have the same Cost Calculation 2");
            Assert.AreEqual((int?) disbursementWip.MarginNo, mainWip.MarginId, message + " Should have the same Margin No");

            if (discountWip != null)
            {
                Assert.AreEqual((DateTime) disbursementWip.TransDate, discountWip.TransactionDate, message + " Should save transaction date");
                Assert.LessOrEqual(beforeSaveTime, discountWip.PostDate, message + " Should have post date greater than when it was submitted");
                Assert.AreEqual((int) disbursementWip.StaffKey, discountWip.StaffId, message + " Should have the same Staff Id");
                Assert.AreEqual((decimal?) disbursementWip.Discount * -1, (decimal?) discountWip.LocalValue, message + " Should have the same discount value");
            }

            if (!string.IsNullOrWhiteSpace(foreignCurrency))
            {
                Assert.AreEqual(ReverseSignForCreditWip((decimal?) disbursementWip.ForeignAmount), mainWip.PreMarginAmount, message + " Should have the same pre margin amount");
                Assert.AreEqual(ReverseSignForCreditWip((decimal?) disbursementWip.ForeignAmount + ((decimal?) disbursementWip.ForeignMargin ?? 0)), mainWip.ForeignValue, message + $" Should have the same Foreign Value based on sum of Foreign Cost ({(decimal?) disbursementWip.ForeignAmount}) and Margin ({(decimal?) disbursementWip.ForeignMargin})");

                if (discountWip != null)
                {
                    Assert.AreEqual(((decimal?) disbursementWip.ForeignDiscount - ((decimal?) disbursementWip.ForeignDiscountForMargin ?? 0)) * -1, (decimal?) discountWip.PreMarginAmount, message + $" Should have the same pre margin amount Discount ({(decimal?) disbursementWip.ForeignDiscount}) - (Foreign Discount For Margin ({(decimal?) disbursementWip.ForeignDiscountForMargin})");
                }
            }
            else
            {
                Assert.AreEqual(ReverseSignForCreditWip((decimal?) disbursementWip.Amount), mainWip.PreMarginAmount, message + " Should have the same pre margin amount");
                Assert.AreEqual(ReverseSignForCreditWip((decimal?) disbursementWip.Amount + ((decimal?) disbursementWip.Margin ?? 0)), mainWip.LocalValue, message + $" Should have the same Local Value based on sum of Local Cost ({(decimal?) disbursementWip.Amount}) and Margin ({(decimal?) disbursementWip.Margin})");

                if (discountWip != null)
                {
                    Assert.AreEqual(((decimal?) disbursementWip.Discount - ((decimal?) disbursementWip.LocalDiscountForMargin ?? 0)) * -1, discountWip.PreMarginAmount, message + $" Should have the same pre margin amount Discount ({(decimal?) disbursementWip.Discount}) - (Local Discount For Margin ({(decimal?) disbursementWip.LocalDiscountForMargin}))");
                }
            }
        }
    }
}