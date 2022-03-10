using NUnit.Framework;

namespace Inprotech.Tests.Integration
{
    public class SplitWipMultiDebtorAttribute : FunctionalCategoryAttribute {}

    public class InterEntityBillingAttribute : FunctionalCategoryAttribute {}
    
    public class FunctionalCategoryAttribute : CategoryAttribute
    {
        public FunctionalCategoryAttribute()
        {
            categoryName = TrimmedTypeName;
        }

        protected string TrimmedTypeName => GetType().Name.Replace("Attribute", string.Empty);
    }
}