using System;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Processor
{
    public enum ItemProcessErrorReason
    {
        DocItemNullOrEmpty,
        DocItemNotFound,
        ItemTypeNotSet,
        SQLQueryNotSet,
        NoField,
        FormFieldNotFound
    }

    [SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable")]
    public class ItemProcessorException : Exception
    {
        public ItemProcessorException(ItemProcessErrorReason reason)
        {
            Reason = reason;
        }

        public ItemProcessorException(ItemProcessErrorReason reason, string message) : base(message)
        {
            Reason = reason;
        }

        public ItemProcessErrorReason Reason { get; }
    }

    public class ItemProcessorInError
    {
        public string Fields { get; set; }
        public string ItemName { get; set; }
        public string ErrorType { get; set; }
        public string ErrorMessage { get; set; }
    }
}