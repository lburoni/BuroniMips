.data
# Variables para listas y mensajes
slist:      .word 0              # Lista de bloques libres
cclist:     .word 0              # Lista de categorías
wclist:     .word 0              # Categoría actual

menu:       .asciiz "\n1 - Nueva Categoria\n2 - Siguiente Categoria\n3 - Categoria Anterior\n4 - Listar Categorias\n5 - Eliminar Categoria\n6 - Añadir Objeto\n7 - Listar Objetos\n8 - Eliminar Objeto\n0 - Salir\nSeleccione una opción: "
success:    .asciiz "Operación realizada con éxito.\n"
error:      .asciiz "Opción no válida.\n"
empty_list: .asciiz "La lista está vacía.\n"
no_next:    .asciiz "No hay más categorías siguientes.\n"
no_prev:    .asciiz "No hay más categorías anteriores.\n"
cat_prompt: .asciiz "Ingrese el nombre de la nueva categoría: "
obj_prompt: .asciiz "Ingrese el nombre del objeto: "
memory_error: .asciiz "Error al asignar memoria.\n"

.text

# Punto de entrada
main:
    la $a0, menu               # Mostrar menú
    li $v0, 4
    syscall

    li $v0, 5                  # Leer opción del usuario
    syscall
    move $t0, $v0

    # Validar opción y redirigir
    li $t1, 0                  # Valor mínimo permitido
    li $t2, 8                  # Valor máximo permitido
    blt $t0, $t1, invalid_option
    bgt $t0, $t2, invalid_option

    # Procesar opción seleccionada
    beq $t0, 1, newcategory
    beq $t0, 2, nextcategory
    beq $t0, 3, prevcategory
    beq $t0, 4, listcategories
    beq $t0, 5, delcategory
    beq $t0, 6, addobject
    beq $t0, 7, listobjects
    beq $t0, 8, delobject
    beq $t0, 0, exit

invalid_option:
    la $a0, error              # Mensaje de error
    li $v0, 4
    syscall
    j main                     # Volver al menú

exit:
    li $v0, 10
    syscall

# Nueva categoría
newcategory:
    li $v0, 9      # Solicitar memoria dinámica
    li $a0, 16     # Tamaño para la categoría
    syscall
    move $t1, $v0  # Guardar puntero a la nueva categoría
    beqz $t1, memory_error_  # Verificar error de asignación de memoria

    # Inicializar bloque de memoria a 0
    move $t2, $t1
    li $t3, 16                 # Tamaño del bloque
    li $t4, 0

init_loop:
    sw $t4, 0($t2)
    addi $t2, $t2, 4
    subi $t3, $t3, 4
    bnez $t3, init_loop

    la $a0, cat_prompt         # Pedir nombre de la categoría
    li $v0, 4
    syscall
    li $v0, 8                  # Leer cadena
    la $a0, 8($t1)             # Espacio para el nombre
    li $a1, 16                 # Tamaño máximo
    syscall

    lw $t0, cclist             # Obtener lista de categorías
    beqz $t0, first_category   # Si está vacía, inicializarla

# Depuración: imprimir valor de t0
print_t0:
    move $a0, $t0
    li $v0, 1
    syscall

    # Insertar al final
loop_end:
    lw $t2, 12($t0)            # Siguiente categoría
    beqz $t2, insert_here
    move $t0, $t2
    j loop_end
insert_here:
    sw $t1, 12($t0)            # Enlazar nueva categoría
    sw $t0, 4($t1)             # Enlazar a la anterior
    j newcategory_done

first_category:
    sw $t1, cclist             # Nueva categoría es la primera
    sw $t1, wclist             # También la actual

newcategory_done:
    la $a0, success
    li $v0, 4
    syscall
    j main

memory_error_:
    la $a0, memory_error
    li $v0, 4
    syscall
    j main

# Siguiente categoría
nextcategory:
    lw $t0, wclist             # Categoría actual
    lw $t1, 12($t0)            # Siguiente categoría
    beqz $t1, no_more_next
    sw $t1, wclist             # Actualizar categoría actual
    la $a0, success
    li $v0, 4
    syscall
    j main

no_more_next:
    la $a0, no_next            # Mensaje de error
    li $v0, 4
    syscall
    j main

# Categoría anterior
prevcategory:
    lw $t0, wclist             # Categoría actual
    lw $t1, 4($t0)             # Categoría anterior
    beqz $t1, no_more_prev
    sw $t1, wclist             # Actualizar categoría actual
    la $a0, success
    li $v0, 4
    syscall
    j main

no_more_prev:
    la $a0, no_prev            # Mensaje de error
    li $v0, 4
    syscall
    j main

# Listar categorías
listcategories:
    lw $t0, cclist             # Primera categoría
    beqz $t0, empty_categories # Si la lista está vacía

listcategories_loop:
    la $a0, ($t0)              # Nombre de la categoría
    li $v0, 4
    syscall
    lw $t0, 12($t0)            # Siguiente categoría
    bnez $t0, listcategories_loop
    j main

empty_categories:
    la $a0, empty_list         # Mostrar mensaje de lista vacía
    li $v0, 4
    syscall
    j main

# Eliminar categoría actual
delcategory:
    lw $t0, wclist             # Categoría actual
    beqz $t0, empty_categories # Si no hay categorías, mensaje

    lw $t1, 4($t0)             # Categoría anterior
    lw $t2, 12($t0)            # Siguiente categoría

# Depuración: imprimir valor de t0
print_t0_del:
    move $a0, $t0
    li $v0, 1
    syscall

    # Si es la primera categoría
    beqz $t1, del_first
    sw $t2, 12($t1)            # Conectar anterior con siguiente
    bnez $t2, update_next
    j del_update

del_first:
    sw $t2, cclist             # Actualizar inicio de la lista
    bnez $t2, update_next

update_next:
    sw $t1, 4($t2)             # Conectar siguiente con anterior

del_update:
    sw $t1, wclist             # Actualizar categoría actual
    la $a0, success            # Mensaje de éxito
    li $v0, 4
    syscall

    # Liberar memoria de la categoría
    # Eliminar se realiza manualmente por diseño MIPS
    j main

# Añadir objeto
addobject:
    lw $t0, wclist          # Cargar la dirección de la categoría actual
    beqz $t0, empty_list    # Verificar si hay categoría seleccionada

    li $v0, 9               # Solicitar memoria dinámica
    li $a0, 20              # Tamaño del objeto
    syscall
    beqz $v0, memory_error_ # Verificar éxito en asignación
    move $t1, $v0           # Guardar puntero al nuevo objeto

    la $a0, obj_prompt      # Pedir nombre del objeto
    li $v0, 4
    syscall
    li $v0, 8               # Leer cadena
    la $a0, 8($t1)          # Espacio para el nombre
    li $a1, 16              # Tamaño máximo
    syscall

    lw $t2, 16($t0)         # Cargar la dirección de la lista de objetos desde la categoría
    beqz $t2, first_object  # Si no hay objetos, inicializar lista

# Depuración: imprimir valor de t0
print_addobject:
    move $a0, $t0
    li $v0, 1
    syscall

addobject_loop:
    lw $t3, 12($t2)         # Leer el siguiente objeto (en offset 12)
    beqz $t3, insert_object # Si el siguiente objeto es nulo, insertar el nuevo objeto
    move $t2, $t3           # Avanzar al siguiente objeto
    j addobject_loop        # Volver al ciclo

insert_object:
    sw $t1, 12($t2)         # Enlazar el nuevo objeto al final
    sw $t2, 4($t1)          # Enlazar a la anterior
    j addobject_done

first_object:
    sw $t1, 16($t0)         # Nuevo objeto como primero
    sw $zero, 4($t1)        # Sin anterior

addobject_done:
    la $a0, success
    li $v0, 4
    syscall
    j main

memory_error__:
    la $a0, memory_error
    li $v0, 4
    syscall
    j main

# Listar objetos
listobjects:
    lw $t0, wclist             # Categoría actual
    beqz $t0, empty_list       # Si no hay categorías

    lw $t1, 16($t0)            # Lista de objetos
    beqz $t1, empty_objects    # Si la lista está vacía

listobjects_loop:
    la $a0, 8($t1)             # Nombre del objeto
    li $v0, 4
    syscall
    lw $t1, 12($t1)            # Siguiente objeto
    bnez $t1, listobjects_loop
    j main

empty_objects:
    la $a0, empty_list
    li $v0, 4
    syscall
    j main

# Eliminar objeto
delobject:
    lw $t0, wclist             # Categoría actual
    beqz $t0, empty_list

    lw $t1, 16($t0)            # Lista de objetos
    beqz $t1, empty_objects

    la $a0, obj_prompt         # Pedir nombre a eliminar
    li $v0, 4
    syscall
    li $v0, 8
    la $a0, 0($sp)             # Leer nombre
    li $a1, 16
    syscall

delobject_loop:
    la $t2, 8($t1)             # Dirección nombre
    li $v0, 42                 # strcmp
    syscall
    beqz $v0, delobject_found
    lw $t1, 12($t1)
    bnez $t1, delobject_loop

    la $a0, empty_list         # No encontrado
    li $v0, 4
    syscall
    j main

delobject_found:
    lw $t2, 4($t1)             # Objeto anterior
    lw $t3, 12($t1)            # Objeto siguiente
    beqz $t2, delobject_first
    sw $t3, 12($t2)
    bnez $t3, reconnect_next

delobject_first:
    sw $t3, 16($t0)            # Nuevo inicio

reconnect_next:
    sw $t2, 4($t3)

    # Liberar memoria
    la $a0, success
    li $v0, 4
    syscall
    j main

    
