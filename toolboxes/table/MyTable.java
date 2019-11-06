import com.jidesoft.grid.*;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.Toolkit;
import java.awt.HeadlessException;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.UnsupportedFlavorException;
import java.io.IOException;
import java.lang.*;
import com.jidesoft.converter.ObjectConverterManager;
import javax.swing.*;
import java.awt.Robot;
import java.awt.AWTException;

 
 public class MyTable extends SortableTable {
    // public MyTable(Object[][] rowData, Object[] columnNames)
    public MyTable()
    {
        super(new FilterableTableModel(new MySortableTableModel(new MyDefaultTableModel(5,5))));
  
        this.addKeyListener(new KeyAdapter()
        {
            @Override
            public void keyReleased(KeyEvent evt)
            {
                copypaste(evt);
            }
        });
        
        CellEditorManager.addCellEditorCustomizer(new CellEditorManager.CellEditorCustomizer(){
            public void customize(CellEditor cellEditor) {
                if(cellEditor instanceof BooleanCheckBoxCellEditor) {
                    ((BooleanCheckBoxCellEditor) cellEditor).setClickCountToStart(1);
                }
                else if(cellEditor instanceof AbstractJideCellEditor) {
                     ((AbstractJideCellEditor) cellEditor).setClickCountToStart(2);
                }
                else if(cellEditor instanceof DefaultCellEditor) {
                    ((DefaultCellEditor) cellEditor).setClickCountToStart(2);
                }
            }
        });        
    }
    
    public void copypaste(KeyEvent evt)
    {
        if(evt.isControlDown())
        {
            if(evt.getKeyCode() == KeyEvent.VK_C )//67)
            {
                // System.out.println("ctrl+c");
                // System.out.println(this.getClipBoardData());
            }
            else if(evt.getKeyCode() == KeyEvent.VK_V)
            {
                // System.out.println("ctrl+v");
                this.pasteClipBoardData();
            }
            else if(evt.getKeyCode() == KeyEvent.VK_X) {
                try {
                    Robot robot = new Robot();
                    robot.keyPress(KeyEvent.VK_CONTROL);
                    robot.keyPress(KeyEvent.VK_C);
                    robot.keyRelease(KeyEvent.VK_C);
                    robot.keyRelease(KeyEvent.VK_CONTROL);
                    this.deleteSelectedDataPortion();
                } catch (AWTException e) {
                    e.printStackTrace();
                }
            }
            else if(evt.getKeyCode() == KeyEvent.VK_DELETE) {
                this.deleteSelectedDataPortion();
            }
 
            evt.consume();
        }
    }
    
    private void deleteSelectedDataPortion() {
        int[] startRow = this.getSelectedRows();
        int[] startCol = this.getSelectedColumns();

        for (int i=0 ; i<startRow.length; i++) { 
            for (int j=0 ; j<startCol.length; j++) { 
                this.setValueAt(null, startRow[i], startCol[j]);
            }
        }
    }
    
    private void pasteClipBoardData(){
        int startRow = this.getSelectedRows()[0]; 
        int startCol = this.getSelectedColumns()[0];
        String[] lines = this.getClipBoardData().split("(\r\n|\r|\n)", -1);

        for (int i=0 ; i<lines.length; i++) { 
            String[] cells = lines[i].split("\t"); 
            for (int j=0 ; j<cells.length; j++) { 
                if (this.getRowCount()>startRow+i && this.getColumnCount()>startCol+j) {
                    this.setValueAt(ObjectConverterManager.fromString(cells[j],this.getModel().getColumnClass(startCol+j)), startRow+i, startCol+j);
                }
            }
        }
    }
    
    private String getClipBoardData(){
        try {
            return (String)Toolkit.getDefaultToolkit().getSystemClipboard().getData(DataFlavor.stringFlavor);
        } catch (HeadlessException e) {
            e.printStackTrace();            
        } catch (UnsupportedFlavorException e) {
            e.printStackTrace();            
        } catch (IOException e) {
            e.printStackTrace();
        }
        return "";
    } 
 }
 
 
