using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("REASON")]
    public class Reason
    {
        public Reason()
        {
            
        }

        public Reason(string code)
        {
            Code = code;
        }

        [Key]
        [MaxLength(2)]
        [Column("REASONCODE")]
        public string Code { get; set; }

        [MaxLength(50)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }
        
        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        [Column("ISPROTECTED")]
        public int? IsProtected { get; set; }

        [Column("SHOWONDEBITNOTE")]
        public int? ShowOnDebitNote { get; set; }

        [Column("USED_BY")]
        public int? UsedBy { get; set; }
    }
    
}