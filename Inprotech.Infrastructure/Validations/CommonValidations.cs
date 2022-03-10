using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Reflection;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Properties;

namespace Inprotech.Infrastructure.Validations
{
    public static class CommonValidations
    {
        static readonly Dictionary<Type, Func<Attribute, object, PropertyInfo, ValidationError>> Validators =
            new Dictionary<Type, Func<Attribute, object, PropertyInfo, ValidationError>>
            {
                {typeof(RequiredAttribute), RequiredFieldValidator},
                {typeof(MaxLengthAttribute), MaxLengthValidator}
            };

        public static IEnumerable<ValidationError> Validate<T>(T model)
        {
            foreach (var prop in model.GetType().GetProperties())
                foreach (var attribute in prop.GetCustomAttributes())
                {
                    Func<Attribute, object, PropertyInfo, ValidationError> validator;
                    if (!Validators.TryGetValue(attribute.GetType(), out validator))
                        continue;

                    var result = validator(attribute, model, prop);
                    if (result == null)
                        continue;

                    yield return result;
                }
        }

        static ValidationError RequiredFieldValidator(Attribute attribute, object model, PropertyInfo p)
        {
            var value = p.GetValue(model, null);
            return (value == null) || string.IsNullOrWhiteSpace(value.ToString()) ? ValidationErrors.Required(p.Name.ToCamelCase()) : null;
        }

        static ValidationError MaxLengthValidator(Attribute attribute, object model, PropertyInfo p)
        {
            var maxLength = (MaxLengthAttribute) attribute;
            var value = p.GetValue(model, null) as string;
            if (!string.IsNullOrWhiteSpace(value) && (value.Length > maxLength.Length))
            {
                var message = string.Format(Resources.ValidationErrorMaxLengthExceeded, maxLength.Length);
                return new ValidationError(p.Name.ToCamelCase(), message);
            }

            return null;
        }
    }
}