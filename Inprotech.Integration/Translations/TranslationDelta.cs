using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Translations
{
    [Table("TranslationDelta")]
    public class TranslationDelta
    {
        [Key]
        public string Culture { get; set; }

        public DateTime LastModified { get; set; }

        public string Delta { get; set; }
    }
}