import os
import csv
import xmlschema

XSD_FOLDER = '../XSD'
OUTPUT_FOLDER = '../XSD/CSV'


def extract_xpaths_from_xsd(xsd_path, filename):
    print(f"Processing: {filename}...")
    try:
        schema = xmlschema.XMLSchema(xsd_path)
    except Exception as e:
        print(f"Error loading {filename}: {e}")
        return []

    extracted_data = []
    
    # FIX 1: Get the full message identifier (e.g., pacs.002.001.12)
    full_message_name = filename.replace('.xsd', '')

    def traverse(element, current_xpath):
        data_type = element.type.local_name if element.type and hasattr(element.type, 'local_name') else 'ComplexType'
        
        extracted_data.append({
            'Message': full_message_name,
            'XPath': current_xpath,
            'XML Tag': getattr(element, 'local_name', ''),
            'Type': data_type,
            'MinOccurs': getattr(element, 'min_occurs', ''),
            'MaxOccurs': getattr(element, 'max_occurs', '')
        })

        if hasattr(element, 'type') and hasattr(element.type, 'content') and element.type.content is not None:
            if hasattr(element.type.content, 'iter_elements'):
                for child in element.type.content.iter_elements():
                    if hasattr(child, 'local_name') and child.local_name:
                        traverse(child, f"{current_xpath}/{child.local_name}")

    for root_name, root_element in schema.elements.items():
        traverse(root_element, f"/{root_name}")

    return extracted_data

def main():
    # Create the output directory if it doesn't exist
    if not os.path.exists(OUTPUT_FOLDER):
        os.makedirs(OUTPUT_FOLDER)

    # Process every XSD in the folder
    for filename in os.listdir(XSD_FOLDER):
        if filename.endswith('.xsd'):
            filepath = os.path.join(XSD_FOLDER, filename)
            file_data = extract_xpaths_from_xsd(filepath, filename)
            
            # FIX 2: Write a separate CSV for each XSD
            if file_data:
                csv_filename = filename.replace('.xsd', '.csv')
                csv_filepath = os.path.join(OUTPUT_FOLDER, csv_filename)
                
                with open(csv_filepath, mode='w', newline='', encoding='utf-8') as csv_file:
                    writer = csv.DictWriter(csv_file, fieldnames=['Message', 'XPath', 'XML Tag', 'Type', 'MinOccurs', 'MaxOccurs'])
                    writer.writeheader()
                    writer.writerows(file_data)
                
                print(f"  -> Saved: {csv_filepath}")
            else:
                print(f"  -> No data found for {filename}")

    print(f"\nAll done! Check the '{OUTPUT_FOLDER}' folder for your separate CSV files.")

if __name__ == "__main__":
    main()