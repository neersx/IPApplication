using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Reflection;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation
{
    public class ValidationResult
    {
        public ValidationResult(string message, Severity severity = Severity.Error)
        {
            Message = message;
            Severity = severity;
            Details = new ExpandoObject();
        }

        public string MessageId { get; set; }

        [JsonConverter(typeof (StringEnumConverter))]
        public Severity Severity { get; private set; }

        public string Message { get; private set; }

        public dynamic Details { get; private set; }
    }

    public static class ValidationResultExtensions
    {
        public static ValidationResult ForInput(this ValidationResult @this, string inputName)
        {
            if (@this == null) throw new ArgumentNullException("this");
            if (string.IsNullOrWhiteSpace(inputName)) throw new ArgumentException("A valid inputName is required.");

            @this.Details.InputName = inputName;
            return @this;
        }

        public static ValidationResult CorrelateWithEntity(this ValidationResult @this, dynamic entity)
        {
            if (@this == null) throw new ArgumentNullException("this");
            if (entity == null) throw new ArgumentNullException("entity");

            @this.Details.EntityType = entity.GetType().Name.Split('_')[0];
            @this.Details.EntityId = entity.Id;
            return @this;
        }

        public static ValidationResult WithCorrelationId(this ValidationResult @this, object id)
        {
            if (@this == null) throw new ArgumentNullException("this");
            @this.Details.CorrelationId = id;
            return @this;
        }

        public static ValidationResult WithMessageId(this ValidationResult @this, string messageId)
        {
            if (@this == null) throw new ArgumentNullException("this");
            @this.MessageId = messageId;
            return @this;
        }
        
        public static ValidationResult Named(this ValidationResult @this, string name)
        {
            if (@this == null) throw new ArgumentNullException("this");
            if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("A valid name is required.");

            @this.Details.Name = name;
            return @this;
        }
        
        public static ValidationResult WithCaseId(this ValidationResult @this, int? caseId)
        {
            if (@this == null) throw new ArgumentNullException("this");

            @this.Details.CaseKey = caseId;
            return @this;
        }
        
        public static ValidationResult WithProgramContext(this ValidationResult @this, int? programContext)
        {
            if (@this == null) throw new ArgumentNullException("this");

            @this.Details.ProgramContext = programContext;
            return @this;
        }

        public static ValidationResult WithNameId(this ValidationResult @this, int? nameId)
        {
            if (@this == null) throw new ArgumentNullException("this");

            @this.Details.NameKey = nameId;
            return @this;
        }

        public static ValidationResult WithValidationKey(this ValidationResult @this, int? validationKey)
        {
            if (@this == null) throw new ArgumentNullException("this");

            @this.Details.ValidationKey = validationKey;
            return @this;
        }
        
        public static ValidationResult WithIsWarning(this ValidationResult @this, bool? isWarning)
        {
            if (@this == null) throw new ArgumentNullException("this");

            @this.Details.IsWarning = isWarning;
            return @this;
        }
        
        public static ValidationResult WithCanOverride(this ValidationResult @this, bool canOverride)
        {
            if (@this == null) throw new ArgumentNullException("this");

            @this.Details.CanOverride = canOverride;
            return @this;
        }
        
        public static ValidationResult WithFunctionalArea(this ValidationResult @this, int functionalArea)
        {
            if (@this == null) throw new ArgumentNullException("this");

            @this.Details.FunctionalArea = functionalArea;
            return @this;
        }

        public static ValidationResult WithDisplayMessage(this ValidationResult @this, string displayMessage)
        {
            if (@this == null) throw new ArgumentNullException("this");

            @this.Details.DisplayMessage = displayMessage;
            return @this;
        }

        public static ValidationResult WithDetails(this ValidationResult @this, object details)
        {
            if (@this == null) throw new ArgumentNullException("this");
            if (details == null) throw new ArgumentNullException("details");

            const BindingFlags bindingflags = BindingFlags.GetProperty | BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public;

            var dictionary = (IDictionary<string, object>) @this.Details;

            foreach (var p in details.GetType().GetProperties(bindingflags))
            {
                dictionary[p.Name] = p.GetValue(details, null);
            }

            return @this;
        }
    }
}