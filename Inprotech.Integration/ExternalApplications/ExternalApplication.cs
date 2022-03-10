using System;
using System.ComponentModel.DataAnnotations;

namespace Inprotech.Integration.ExternalApplications
{
    public class ExternalApplication
    {
        public int Id { get; set; }

        [Required]
        public string Name { get; set; }

        public string Code { get; set; }

        [Required]
        public bool IsInternalUse { get; set; }

        [Required]
        public DateTime? CreatedOn { get; set; }

        [Required]
        public int? CreatedBy { get; set; }

        public virtual ExternalApplicationToken ExternalApplicationToken { get; set; }
    }
}
