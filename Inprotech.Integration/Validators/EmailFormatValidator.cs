using System.Text.RegularExpressions;

namespace Inprotech.Integration.Validators
{
    public class EmailFormatValidator : BaseValidator
    {
        protected override bool Validate<T>(T value)
        {
            return Regex.IsMatch(value as string ?? string.Empty, @"^[_a-zA-Z0-9]+(\.[_a-zA-Z0-9]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$");
        }
    }
}
