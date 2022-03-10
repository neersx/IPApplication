using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Integration.Validators
{
    public class NullEmptyStringValidator : BaseValidator
    {
        protected override bool Validate<T>(T value)
        {
            switch (value)
            {
                case IEnumerable<string> values:
                {
                    return !values.Any(string.IsNullOrWhiteSpace);
                }
                default:
                    return string.IsNullOrWhiteSpace(value?.ToString());
            }
        }
    }
}
