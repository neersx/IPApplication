using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("PROPERTYTYPE")]
    public class PropertyType
    {
        [Obsolete("For persistence only.")]
        public PropertyType()
        {
        }

        public PropertyType(string code, string name)
        {
            if(string.IsNullOrEmpty(name)) throw new ArgumentException("A valid Property Type is required.");
            if(string.IsNullOrWhiteSpace(code)) throw new ArgumentException("A valid Property Type code is required.");

            Name = name;
            Code = code;
        }

        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Key]
        [Column("PROPERTYTYPE")]
        [MaxLength(1)]
        public string Code { get; set; }

        [MaxLength(50)]
        [Column("PROPERTYNAME")]
        public string Name { get; set; }

        [Column("CRMONLY")]
        public bool? CrmOnly { get; protected set; }

        [Column("PROPERTYNAME_TID")]
        public int? NameTId { get; protected set; }

        [Column("ALLOWSUBCLASS")]
        public decimal AllowSubClass { get; set; }
        
        [Column("ICONIMAGEID")]
        public int? ImageId { get; set; }
        
        [ForeignKey("ImageId")]
        public virtual Image IconImage { get; set; }
        
        public override string ToString()
        {
            return Name;
        }

        public void SetCrmOnly(bool crmOnly)
        {
            CrmOnly = crmOnly;
        }
    }
}