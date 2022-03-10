using System;
using System.ComponentModel.DataAnnotations;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Uspto.PrivatePair.Certificates
{
    public class Certificate : ISoftDeleteable
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage",
            "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Certificate()
        {
        }

        public int Id { get; set; }

        [Required]
        public string Name { get; set; }

        [Required]
        public string FileName { get; set; }

        [Required]
        public string CustomerNumbers { get; set; }

        [Required]
        public string Password { get; set; }

        [Required]
        public string Content { get; set; }

        [Required]
        public DateTime CreatedOn { get; set; }

        [Required]
        public int CreatedBy { get; set; }

        public bool IsDeleted { get; set; }
        
        public DateTime? DeletedOn { get; set; }
        
        public int? DeletedBy { get; set; }
    }
}