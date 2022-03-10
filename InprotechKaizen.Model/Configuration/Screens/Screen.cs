using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration.Screens
{
    [Table("SCREENS")]
    public class Screen
    {
        [Key]
        [Column("SCREENNAME")]
        [MaxLength(50)]
        public string ScreenName { get; set; }

        [MaxLength(50)]
        [Column("SCREENTITLE")]
        public string ScreenTitle { get; set; }

        [MaxLength(1)]
        [Column("SCREENTYPE")]
        public string ScreenType { get; set; }

        [Column("SCREENTITLE_TID")]
        public int? ScreenTitleTId { get; set; }
    }
}
