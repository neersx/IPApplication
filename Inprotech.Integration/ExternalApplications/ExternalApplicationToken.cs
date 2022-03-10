using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.ExternalApplications
{
    public class ExternalApplicationToken
    {
        [Key]
        [Required]
        public int ExternalApplicationId { get; set; }

        [Required]
        public string Token { get; set; }

        public DateTime? ExpiryDate { get; set; }

        public bool IsActive { get; set; }

        [Required]
        public DateTime CreatedOn { get; set; }

        [Required]
        public int CreatedBy { get; set; }

        [Required]
        [ForeignKey("ExternalApplicationId")]
        public virtual ExternalApplication ExternalApplication { get; set; }
    }
}
