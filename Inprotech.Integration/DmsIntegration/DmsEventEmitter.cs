namespace Inprotech.Integration.DmsIntegration
{
    public interface IDmsEventEmitter
    {
        void Emit(DocumentManagementEvent e);
    }

    public class DmsEventEmitter : IDmsEventEmitter
    {
        readonly IDmsEventCapture _dmsEventCapture;

        public DmsEventEmitter(IDmsEventCapture dmsEventCapture)
        {
            _dmsEventCapture = dmsEventCapture;
        }

        public void Emit(DocumentManagementEvent e)
        {
            // better to use a bus
            _dmsEventCapture.Capture(e);
        }
    }
}