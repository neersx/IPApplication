using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.TempStorage
{
    [Table("TEMPSTORAGE")]
    public class TempStorage
    {
         [Obsolete("For persistence only.")]
         public TempStorage()
         {

         }

         public TempStorage(string data)
         {
             if(data == null) throw new ArgumentNullException("data");
             Value = data;
         }

         [Key]
         [Column("ID")]
         public long Id { get; protected set; }

         [Required]
         [Column("DATA")]
         public string Value { get; set; }

    }
}
