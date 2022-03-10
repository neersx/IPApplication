using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Names
{

    [Table("NAMEALIAS")]
    public class NameAlias
    {

        [Key]
        [Column("ALIASNO")]
        public int AliasId { get; protected set; }

        [Column("NAMENO")]
        public int NameId { get; set; }
        
        public virtual Name Name { get; set; }

        [Column("ALIASTYPE")]
        public virtual NameAliasType AliasType { get; set; }

        [MaxLength(30)]
        [Column("ALIAS")]
        public string Alias { get; set; }

        [Column("COUNTRYCODE")]
        public virtual Country Country { get; set; }

        [Column("PROPERTYTYPE")]
        public virtual PropertyType PropertyType { get; set; }
    }
}
