using Inprotech.Infrastructure.Web;

namespace Inprotech.Integration.Validators
{
    public abstract class BaseValidator
    {
        protected BaseValidator NextValidator { get; private set; }

        public ExecutionResult ValidationResult { get; set; }

        public bool IsValid<T>(T value)
        {
            var isValid = Validate(value);
            return isValid && (NextValidator?.IsValid<T>(value) ?? true);
        }

        public bool IsValid<T>(T value, out ExecutionResult errors)
        {
            if (!Validate(value))
            {
                errors = this.ValidationResult;
                return false;
            }

            ExecutionResult nextError = null;
            var isNextValid = NextValidator?.IsValid<T>(value, out nextError) ?? true;
            errors = nextError;

            return isNextValid;
        }

        protected abstract bool Validate<T>(T value);
        public BaseValidator Then(BaseValidator next)
        {
            SetNextValidator(this, next);
            return this;
        }

        static void SetNextValidator(BaseValidator target, BaseValidator next)
        {
            while (true)
            {
                if (target.NextValidator != null)
                {
                    target = target.NextValidator;
                    continue;
                }

                target.NextValidator = next;
                break;
            }
        }
    }
}
