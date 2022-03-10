using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Tax
{
    [Table("TAXRATES")]
    public class TaxRate
    {
        public TaxRate()
        {
        }

        public TaxRate(string id)
        {
            Code = id;
        }

        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Key]
        [Column("TAXCODE")]
        [MaxLength(3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public string Code { get; set; }

        [MaxLength(30)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }
    }
}