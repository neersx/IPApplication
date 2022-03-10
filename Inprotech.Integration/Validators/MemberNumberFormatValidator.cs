using System.Text.RegularExpressions;

namespace Inprotech.Integration.Validators
{
    public class CustomerNumberFormatValidator : BaseValidator
    {
        protected override bool Validate<T>(T value)
        {
            return Regex.IsMatch(value as string ?? string.Empty, @"^[0-9]+(,[ 0-9]+)*,*$");
        }
    }
}
