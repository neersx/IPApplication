using System.Collections.Generic;

namespace Inprotech.Infrastructure.Validations
{
    public enum Severity
    {
        Information,
        Warning,
        Error
    }
    public class ValidationError
    {
        public ValidationError(string field, string message, Severity severity = Severity.Error)
        {
            Field = field;
            Message = message;
            Severity = severity;
        }

        public ValidationError(string topic, string field, dynamic id, string message, bool displayMessage = false, Severity severity = Severity.Error)
        {
            Topic = topic;
            Field = field;
            Id = id;
            Message = message;
            DisplayMessage = displayMessage;
            Severity = severity;
        }

        public ValidationError(string field, string message, string customValidationMessage, bool displayMessage = false, Severity severity = Severity.Error)
        {
            Field = field;
            Message = message;
            CustomValidationMessage = customValidationMessage;
            DisplayMessage = displayMessage;
            Severity = severity;
        }

        public string Topic { get; private set; }

        public string Field { get; private set; }

        public dynamic Id { get; private set; }

        public string Message { get; private set; }

        public string CustomValidationMessage { get; private set; }

        public bool DisplayMessage { get; private set; }

        public Severity Severity { get; private set; }

        public dynamic CustomData { get; set; }
    }

    public static class ValidationErrors
    {
        public static ValidationError NotUnique(string field)
        {
            return new ValidationError(field, "field.errors.notunique");
        }

        public static ValidationError NotUnique(string topic, string field, dynamic id = null)
        {
            return new ValidationError(topic, field, id, "field.errors.notunique");
        }

        public static ValidationError Invalid(string topic, string field, string messageId)
        {
            return new ValidationError(topic, field, null, messageId, true);
        }

        public static ValidationError SetError(string topic, string field, string messageId, bool displayMessage, dynamic id = null, Severity severity = Severity.Error)
        {
            return new ValidationError(topic, field, id, messageId, displayMessage, severity);
        }

        public static ValidationError SetCustomError(string field, string messageId, string customValidationMessage, bool displayMessage)
        {
            return new ValidationError(field, messageId, customValidationMessage, displayMessage);
        }

        public static ValidationError SetCustomError(string topic, string field, string messageId, dynamic customData, bool displayMessage, dynamic id = null)
        {
            return new ValidationError(topic, field, id, messageId, displayMessage) { CustomData = customData };
        }

        public static ValidationError SetError(string field, string messageId, Severity severity = Severity.Error)
        {
            return new ValidationError(field, messageId, severity);
        }

        public static ValidationError Required(string field)
        {
            return new ValidationError(field, "field.errors.required");
        }

        public static ValidationError Required(string topic, string field, dynamic id = null)
        {
            return new ValidationError(topic, field, id, "field.errors.required");
        }

        public static ValidationError TopicError(string topic, string message)
        {
            return new ValidationError(topic, null, null, message);
        }

        public static dynamic AsErrorResponse(this IEnumerable<ValidationError> errors)
        {
            return new
            {
                Errors = errors
            };
        }

        public static dynamic AsErrorResponse(this ValidationError error)
        {
            return new
            {
                Error = error
            };
        }

        public static dynamic AsHandled(this string error)
        {
            return error.AsErrorResponse();
        }

        static dynamic AsErrorResponse(this string error)
        {
            return new
            {
                Errors = new[]
                                {
                                    new ValidationError(null, error)
                                }
            };
        }
    }

    public class KnownSqlErrors
    {
        public const string CannotDelete = "entity.cannotdelete";
        public const string CannotDeleteProtectedCaseType = "entity.protectedcasetype";
    }
    
}